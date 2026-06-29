import {
  postChatMessagesRequestSchema,
  postChatMessagesResponseSchema,
  type PostChatMessagesResponse
} from "../contracts/chat-messages.js";
import { errorMessageByCode, type ErrorCode } from "../contracts/errors.js";
import { createRequestContext } from "../core/request-context.js";
import { jsonResponse, type JsonResponse } from "../core/http.js";
import { consoleLogger, type Logger } from "../core/logger.js";
import { parseBearerToken, type AuthVerifier } from "../services/auth.js";
import type { CryptoService } from "../services/crypto.js";
import { findIdempotentChatResponse } from "../services/chat-idempotency-lookup.js";
import { persistExtractionResults } from "../services/entity-builder.js";
import type { GroqClient } from "../services/groq-client.js";
import { mapRequestErrorToCode } from "../services/groq-errors.js";
import {
  buildChatExtractionDeveloperPrompt,
  CHAT_EXTRACTION_SYSTEM_PROMPT
} from "../services/groq-prompts.js";
import type { PersistenceRepository } from "../services/persistence.js";
import type { RateLimiter } from "../services/rate-limit.js";
import type { GroqUsageRepository } from "../services/groq-usage.js";
import { utcDateString } from "../services/groq-usage.js";
import type { UserSettingsRepository } from "../services/user-settings.js";

const FUNCTION_NAME = "post_chat_messages";

export interface ChatMessagesHandlerDeps {
  authVerifier: AuthVerifier;
  userSettingsRepository: UserSettingsRepository;
  groqClient: GroqClient;
  groqUsageRepository: GroqUsageRepository;
  groqDailyTokenLimit: number;
  cryptoService: CryptoService;
  persistenceRepository: PersistenceRepository;
  rateLimiter?: RateLimiter;
  logger?: Logger;
}

export interface HandleRequestInput {
  body: unknown;
  authorizationHeader: string | null;
}

const toErrorResponse = (
  requestId: string,
  code: ErrorCode,
  logger: Logger,
  startedAt: number,
  userId?: string
): JsonResponse => {
  logger.error("Request failed", {
    request_id: requestId,
    function_name: FUNCTION_NAME,
    user_id: userId,
    error_code: code,
    latency_ms: Date.now() - startedAt
  });

  const statusByCode: Record<ErrorCode, number> = {
    VALIDATION_ERROR: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    CONFLICT: 409,
    GROQ_TIMEOUT: 504,
    GROQ_UNAVAILABLE: 503,
    RATE_LIMITED: 429,
    INTERNAL_ERROR: 500
  };

  return jsonResponse(statusByCode[code], {
    error: {
      code,
      message: errorMessageByCode[code],
      request_id: requestId
    }
  });
};

export const createChatMessagesHandler = (deps: ChatMessagesHandlerDeps) => {
  const logger = deps.logger ?? consoleLogger;

  return async (input: HandleRequestInput): Promise<JsonResponse> => {
    const context = createRequestContext();
    const token = parseBearerToken(input.authorizationHeader);

    if (!token) {
      return toErrorResponse(context.requestId, "UNAUTHORIZED", logger, context.startedAt);
    }

    let userId = "";
    try {
      const auth = await deps.authVerifier.verifyAccessToken(token);
      userId = auth.userId;
    } catch {
      return toErrorResponse(context.requestId, "UNAUTHORIZED", logger, context.startedAt);
    }

    if (deps.rateLimiter) {
      const limit = await deps.rateLimiter.consume(`${FUNCTION_NAME}:${userId}`);
      if (!limit.allowed) {
        return toErrorResponse(context.requestId, "RATE_LIMITED", logger, context.startedAt, userId);
      }
    }

    await deps.userSettingsRepository.ensureEncryptionKeyId(userId);

    const parsedBody = postChatMessagesRequestSchema.safeParse(input.body);
    if (!parsedBody.success) {
      return toErrorResponse(
        context.requestId,
        "VALIDATION_ERROR",
        logger,
        context.startedAt,
        userId
      );
    }

    const cachedResponse = await findIdempotentChatResponse(
      deps.persistenceRepository,
      deps.cryptoService,
      userId,
      parsedBody.data.client_message_id
    );
    if (cachedResponse) {
      const parsedCached = postChatMessagesResponseSchema.safeParse(cachedResponse);
      if (parsedCached.success) {
        logger.info("Request completed (idempotent)", {
          request_id: context.requestId,
          function_name: FUNCTION_NAME,
          user_id: userId,
          latency_ms: Date.now() - context.startedAt
        });
        return jsonResponse(200, parsedCached.data);
      }
    }

    const userSettings = await deps.userSettingsRepository.findByUserId(userId);
    if (!userSettings) {
      return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
    }

    let extractionReply = "";
    let createdEntities: PostChatMessagesResponse["created_entities"] = [];
    try {
      const usageDate = utcDateString();
      const usedTokens = await deps.groqUsageRepository.getDailyTokensUsed(userId, usageDate);
      if (usedTokens >= deps.groqDailyTokenLimit) {
        return toErrorResponse(context.requestId, "RATE_LIMITED", logger, context.startedAt, userId);
      }

      const currentTime = new Date().toISOString();
      const groqResult = await deps.groqClient.extract({
        systemPrompt: CHAT_EXTRACTION_SYSTEM_PROMPT,
        developerPrompt: buildChatExtractionDeveloperPrompt({
          currentTimeIso: currentTime,
          timezone: userSettings.timezone,
          userId,
          forcedCategory: parsedBody.data.forced_category
        }),
        userPrompt: parsedBody.data.text
      });
      const extraction = groqResult.extraction;
      extractionReply = extraction.reply_message;

      const userMessageEncryption = await deps.cryptoService.encryptText(parsedBody.data.text);
      const analysisResultsEncryption = await deps.cryptoService.encryptText(JSON.stringify(extraction));
      const assistantMessageEncryption = await deps.cryptoService.encryptText(extractionReply);
      const messageId = crypto.randomUUID();

      const persistenceResult = await persistExtractionResults(
        deps.persistenceRepository,
        deps.cryptoService,
        {
          messageId,
          userId,
          clientMessageId: parsedBody.data.client_message_id,
          userPlainText: parsedBody.data.text,
          extraction,
          analysisResultsEncrypted: analysisResultsEncryption,
          textEncryption: userMessageEncryption,
          assistantTextEncryption: assistantMessageEncryption
        }
      );
      createdEntities = persistenceResult.createdEntities;
      const assistantMessageId = persistenceResult.assistantMessageId;

      const responseBody: PostChatMessagesResponse = {
        message_id: messageId,
        assistant_message_id: assistantMessageId,
        confirmation_text: extractionReply,
        created_entities: createdEntities
      };

      const parsedResponse = postChatMessagesResponseSchema.parse(responseBody);
      if (groqResult.tokensUsed > 0) {
        await deps.groqUsageRepository.addDailyTokens(userId, usageDate, groqResult.tokensUsed);
      }
      logger.info("Request completed", {
        request_id: context.requestId,
        function_name: FUNCTION_NAME,
        user_id: userId,
        latency_ms: Date.now() - context.startedAt
      });

      return jsonResponse(200, parsedResponse);
    } catch (error) {
      if (error instanceof Error && error.message === "NOT_FOUND") {
        return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
      }
      logger.error("Request failed", {
        request_id: context.requestId,
        function_name: FUNCTION_NAME,
        user_id: userId,
        error_code: "INTERNAL_ERROR",
        error_message: error instanceof Error ? error.message : "unknown",
        latency_ms: Date.now() - context.startedAt
      });
      const code = mapRequestErrorToCode(error);
      return toErrorResponse(context.requestId, code, logger, context.startedAt, userId);
    }
  };
};
