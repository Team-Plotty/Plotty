import {
  deleteEntityResponseSchema,
  type DeleteEntityResponse,
  type EntityType
} from "../contracts/chat-messages.js";
import { type ErrorCode, errorMessageByCode } from "../contracts/errors.js";
import { jsonResponse, type JsonResponse } from "../core/http.js";
import { consoleLogger, type Logger } from "../core/logger.js";
import { createRequestContext } from "../core/request-context.js";
import { parseBearerToken, type AuthVerifier } from "../services/auth.js";
import type { PersistenceRepository } from "../services/persistence.js";

const FUNCTION_NAME = "delete_entity";

export interface DeleteEntityHandlerDeps {
  authVerifier: AuthVerifier;
  persistenceRepository: PersistenceRepository;
  logger?: Logger;
}

export interface DeleteEntityInput {
  authorizationHeader: string | null;
  type: EntityType;
  id: string;
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

export const createDeleteEntityHandler = (deps: DeleteEntityHandlerDeps) => {
  const logger = deps.logger ?? consoleLogger;

  return async (input: DeleteEntityInput): Promise<JsonResponse> => {
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

    const deleted = await deps.persistenceRepository.softDeleteEntity({
      id: input.id,
      userId,
      type: input.type
    });

    if (!deleted) {
      return toErrorResponse(context.requestId, "NOT_FOUND", logger, context.startedAt, userId);
    }

    const response: DeleteEntityResponse = {
      deleted: true,
      type: input.type,
      id: input.id
    };
    const parsed = deleteEntityResponseSchema.parse(response);
    logger.info("Request completed", {
      request_id: context.requestId,
      function_name: FUNCTION_NAME,
      user_id: userId,
      latency_ms: Date.now() - context.startedAt
    });
    return jsonResponse(200, parsed);
  };
};
