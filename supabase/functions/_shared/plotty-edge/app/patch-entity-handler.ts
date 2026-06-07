import {
  patchEntityRequestSchema,
  patchEntityResponseSchema,
  type EntityType,
  type PatchEntityResponse
} from "../contracts/chat-messages.js";
import { type ErrorCode, errorMessageByCode } from "../contracts/errors.js";
import { jsonResponse, type JsonResponse } from "../core/http.js";
import { consoleLogger, type Logger } from "../core/logger.js";
import { createRequestContext } from "../core/request-context.js";
import { parseBearerToken, type AuthVerifier } from "../services/auth.js";
import type { CryptoService } from "../services/crypto.js";
import type { PersistenceRepository } from "../services/persistence.js";
import type { RateLimiter } from "../services/rate-limit.js";

const FUNCTION_NAME = "patch_entity";

export interface PatchEntityHandlerDeps {
  authVerifier: AuthVerifier;
  cryptoService: CryptoService;
  persistenceRepository: PersistenceRepository;
  rateLimiter?: RateLimiter;
  logger?: Logger;
}

export interface PatchEntityInput {
  authorizationHeader: string | null;
  type: EntityType;
  id: string;
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

export const createPatchEntityHandler = (deps: PatchEntityHandlerDeps) => {
  const logger = deps.logger ?? consoleLogger;

  return async (input: PatchEntityInput): Promise<JsonResponse> => {
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

    const parsedBody = patchEntityRequestSchema.safeParse(input.body);
    if (!parsedBody.success) {
      return toErrorResponse(
        context.requestId,
        "VALIDATION_ERROR",
        logger,
        context.startedAt,
        userId
      );
    }

    const updatePayload: {
      id: string;
      userId: string;
      type: EntityType;
      titleEncrypted?: string;
      iv?: string;
      startAt?: string;
      dueDate?: string;
      contentEncrypted?: string;
    } = {
      id: input.id,
      userId,
      type: input.type
    };

    if (parsedBody.data.title) {
      const encryptedTitle = await deps.cryptoService.encryptText(parsedBody.data.title);
      updatePayload.titleEncrypted = encryptedTitle.data;
      updatePayload.iv = encryptedTitle.iv;
    }
    if (parsedBody.data.start_at) updatePayload.startAt = parsedBody.data.start_at;
    if (parsedBody.data.due_date) updatePayload.dueDate = parsedBody.data.due_date;
    if (parsedBody.data.content) {
      const encryptedContent = await deps.cryptoService.encryptText(parsedBody.data.content);
      updatePayload.contentEncrypted = encryptedContent.data;
    }

    const updated = await deps.persistenceRepository.updateEntity(updatePayload);
    if (!updated) {
      return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
    }

    const title = await deps.cryptoService.decryptText({
      iv: updated.iv,
      data: updated.titleEncrypted
    });

    const response: PatchEntityResponse = {
      entity: {
        type: updated.type,
        id: updated.id,
        title,
        start_at: updated.startAt,
        due_date: updated.dueDate
      }
    };
    const parsed = patchEntityResponseSchema.parse(response);
    logger.info("Request completed", {
      request_id: context.requestId,
      function_name: FUNCTION_NAME,
      user_id: userId,
      latency_ms: Date.now() - context.startedAt
    });
    return jsonResponse(200, parsed);
  };
};
