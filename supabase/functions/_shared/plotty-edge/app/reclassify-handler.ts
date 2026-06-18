import {
  postReclassifyRequestSchema,
  postReclassifyResponseSchema,
  type PostReclassifyResponse
} from "../contracts/reclassify.ts";
import { type ErrorCode, errorMessageByCode } from "../contracts/errors.ts";
import { jsonResponse, type JsonResponse } from "../core/http.ts";
import { consoleLogger, type Logger } from "../core/logger.ts";
import { createRequestContext } from "../core/request-context.ts";
import { parseBearerToken, type AuthVerifier } from "../services/auth.ts";
import type { CryptoService } from "../services/crypto.ts";
import { entityReadModelToDto } from "../services/entity-dto-mapper.ts";
import type { PersistenceRepository } from "../services/persistence.ts";
import { reclassifyEntity } from "../services/reclassify.ts";
import type { RateLimiter } from "../services/rate-limit.ts";
import type { UserSettingsRepository } from "../services/user-settings.ts";

const FUNCTION_NAME = "post_chat_reclassify";

export interface ReclassifyHandlerDeps {
  authVerifier: AuthVerifier;
  cryptoService: CryptoService;
  persistenceRepository: PersistenceRepository;
  userSettingsRepository: UserSettingsRepository;
  rateLimiter?: RateLimiter;
  logger?: Logger;
}

export interface ReclassifyHandlerInput {
  authorizationHeader: string | null;
  body: unknown;
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

export const createReclassifyHandler = (deps: ReclassifyHandlerDeps) => {
  const logger = deps.logger ?? consoleLogger;

  return async (input: ReclassifyHandlerInput): Promise<JsonResponse> => {
    const context = createRequestContext();
    const token = parseBearerToken(input.authorizationHeader);
    if (!token) {
      return toErrorResponse(context.requestId, "UNAUTHORIZED", logger, context.startedAt);
    }

    let userId = "";
    try {
      userId = (await deps.authVerifier.verifyAccessToken(token)).userId;
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

    const parsedBody = postReclassifyRequestSchema.safeParse(input.body);
    if (!parsedBody.success) {
      return toErrorResponse(
        context.requestId,
        "VALIDATION_ERROR",
        logger,
        context.startedAt,
        userId
      );
    }

    try {
      const result = await reclassifyEntity(deps.persistenceRepository, deps.cryptoService, {
        userId,
        sourceType: parsedBody.data.source.type,
        sourceId: parsedBody.data.source.id,
        targetType: parsedBody.data.target_type
      });

      const migratedEntity = await entityReadModelToDto(deps.cryptoService, result.migratedEntity);
      const response: PostReclassifyResponse = {
        confirmation_text: result.confirmationText,
        migrated_entity: migratedEntity
      };
      const parsed = postReclassifyResponseSchema.parse(response);
      logger.info("Request completed", {
        request_id: context.requestId,
        function_name: FUNCTION_NAME,
        user_id: userId,
        latency_ms: Date.now() - context.startedAt
      });
      return jsonResponse(200, parsed);
    } catch (error) {
      if (error instanceof Error && error.message === "NOT_FOUND") {
        return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
      }
      return toErrorResponse(context.requestId, "INTERNAL_ERROR", logger, context.startedAt, userId);
    }
  };
};
