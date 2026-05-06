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
import type { GroqClient } from "../services/groq-client.js";
import type { UserSettingsRepository } from "../services/user-settings.js";

const FUNCTION_NAME = "post_chat_messages";

export interface ChatMessagesHandlerDeps {
  authVerifier: AuthVerifier;
  userSettingsRepository: UserSettingsRepository;
  groqClient: GroqClient;
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

    const userSettings = await deps.userSettingsRepository.findByUserId(userId);
    if (!userSettings) {
      return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
    }

    let extractionReply = "";
    try {
      const currentTime = new Date().toISOString();
      const extraction = await deps.groqClient.extract({
        systemPrompt:
          "あなたは Plotty の AI アシスタントです。指定のJSON形式で抽出結果のみ返してください。",
        developerPrompt: `current_time: ${currentTime}\ntimezone: ${userSettings.timezone}\nuser_id: ${userId}`,
        userPrompt: parsedBody.data.text
      });
      extractionReply = extraction.reply_message;
    } catch (error) {
      const code = error instanceof Error && error.name === "AbortError" ? "GROQ_TIMEOUT" : "GROQ_UNAVAILABLE";
      return toErrorResponse(context.requestId, code, logger, context.startedAt, userId);
    }

    const responseBody: PostChatMessagesResponse = {
      message_id: crypto.randomUUID(),
      confirmation_text: extractionReply,
      created_entities: []
    };

    const parsedResponse = postChatMessagesResponseSchema.parse(responseBody);
    logger.info("Request completed", {
      request_id: context.requestId,
      function_name: FUNCTION_NAME,
      user_id: userId,
      latency_ms: Date.now() - context.startedAt
    });

    return jsonResponse(200, parsedResponse);
  };
};
