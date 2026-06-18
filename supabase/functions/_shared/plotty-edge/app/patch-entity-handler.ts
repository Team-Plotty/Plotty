import {
  patchEntityRequestSchema,
  patchEntityResponseSchema,
  type EntityType,
  type PatchEntityResponse
} from "../contracts/chat-messages.ts";
import { type ErrorCode, errorMessageByCode } from "../contracts/errors.ts";
import { jsonResponse, type JsonResponse } from "../core/http.ts";
import { consoleLogger, type Logger } from "../core/logger.ts";
import { createRequestContext } from "../core/request-context.ts";
import { parseBearerToken, type AuthVerifier } from "../services/auth.ts";
import type { CryptoService } from "../services/crypto.ts";
import { entityReadModelToDto } from "../services/entity-dto-mapper.ts";
import type { EntityUpdateInput, PersistenceRepository } from "../services/persistence.ts";
import type { RateLimiter } from "../services/rate-limit.ts";

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

const hashTitle = async (title: string): Promise<string> => {
  const payload = new TextEncoder().encode(title);
  const digest = await crypto.subtle.digest("SHA-256", payload);
  const bytes = Array.from(new Uint8Array(digest));
  return bytes.map((byte) => byte.toString(16).padStart(2, "0")).join("");
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

    const updatePayload: EntityUpdateInput = {
      id: input.id,
      userId,
      type: input.type
    };

    const hasEncryptedField =
      parsedBody.data.title !== undefined ||
      parsedBody.data.notes !== undefined ||
      parsedBody.data.content !== undefined;

    let entityIv: string | undefined;
    if (hasEncryptedField) {
      const existing = await deps.persistenceRepository.getEntityById({
        userId,
        type: input.type,
        id: input.id
      });
      if (!existing) {
        return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
      }
      entityIv = existing.iv;
    }

    if (parsedBody.data.title) {
      updatePayload.titleEncrypted = await deps.cryptoService.encryptDataWithIv(
        parsedBody.data.title,
        entityIv!
      );
      updatePayload.titleHash = await hashTitle(parsedBody.data.title);
    }
    if (parsedBody.data.start_at !== undefined) updatePayload.startAt = parsedBody.data.start_at;
    if (parsedBody.data.end_at !== undefined) updatePayload.endAt = parsedBody.data.end_at;
    if (parsedBody.data.is_all_day !== undefined) updatePayload.isAllDay = parsedBody.data.is_all_day;
    if (parsedBody.data.location !== undefined) updatePayload.location = parsedBody.data.location;
    if (parsedBody.data.notes !== undefined) {
      updatePayload.originTextEncrypted = await deps.cryptoService.encryptDataWithIv(
        parsedBody.data.notes,
        entityIv!
      );
    }
    if (parsedBody.data.due_date !== undefined) updatePayload.dueDate = parsedBody.data.due_date;
    if (parsedBody.data.is_completed !== undefined) {
      updatePayload.isCompleted = parsedBody.data.is_completed;
    }
    if (parsedBody.data.priority !== undefined) {
      updatePayload.priority = parsedBody.data.priority as 1 | 2 | 3;
    }
    if (parsedBody.data.content !== undefined) {
      updatePayload.contentEncrypted = await deps.cryptoService.encryptDataWithIv(
        parsedBody.data.content,
        entityIv!
      );
    }
    if (parsedBody.data.is_pinned !== undefined) updatePayload.isPinned = parsedBody.data.is_pinned;

    const updated = await deps.persistenceRepository.updateEntity(updatePayload);
    if (!updated) {
      return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
    }

    const entity = await entityReadModelToDto(deps.cryptoService, updated);
    const response: PatchEntityResponse = { entity };
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
