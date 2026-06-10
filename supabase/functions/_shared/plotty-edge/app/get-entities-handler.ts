import {
  getEntitiesResponseSchema,
  type EntityType,
  type GetEntitiesResponse
} from "../contracts/chat-messages.ts";
import { type ErrorCode, errorMessageByCode } from "../contracts/errors.ts";
import { jsonResponse, type JsonResponse } from "../core/http.ts";
import { consoleLogger, type Logger } from "../core/logger.ts";
import { createRequestContext } from "../core/request-context.ts";
import { parseBearerToken, type AuthVerifier } from "../services/auth.ts";
import type { CryptoService } from "../services/crypto.ts";
import { entityReadModelToDto } from "../services/entity-dto-mapper.ts";
import type { PersistenceRepository } from "../services/persistence.ts";
import type { RateLimiter } from "../services/rate-limit.ts";
import { getEntitiesQuerySchema } from "../contracts/chat-messages.ts";

const FUNCTION_NAME = "get_entities";

export interface GetEntitiesHandlerDeps {
  authVerifier: AuthVerifier;
  cryptoService: CryptoService;
  persistenceRepository: PersistenceRepository;
  rateLimiter?: RateLimiter;
  logger?: Logger;
}

export interface GetEntitiesInput {
  authorizationHeader: string | null;
  query: { type?: string; limit?: string };
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

const parseType = (value?: string): EntityType | undefined => {
  if (value === "schedule" || value === "task" || value === "memo") {
    return value;
  }
  return undefined;
};

export const createGetEntitiesHandler = (deps: GetEntitiesHandlerDeps) => {
  const logger = deps.logger ?? consoleLogger;

  return async (input: GetEntitiesInput): Promise<JsonResponse> => {
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

    const parsedQuery = getEntitiesQuerySchema.safeParse({
      type: parseType(input.query.type),
      limit: input.query.limit
    });
    if (!parsedQuery.success) {
      return toErrorResponse(
        context.requestId,
        "VALIDATION_ERROR",
        logger,
        context.startedAt,
        userId
      );
    }

    const rows = await deps.persistenceRepository.listEntities({
      userId,
      type: parsedQuery.data.type,
      limit: parsedQuery.data.limit
    });

    const items = await Promise.all(rows.map((row) => entityReadModelToDto(deps.cryptoService, row)));
    const response: GetEntitiesResponse = {
      items,
      next_cursor: null
    };

    const parsed = getEntitiesResponseSchema.parse(response);
    logger.info("Request completed", {
      request_id: context.requestId,
      function_name: FUNCTION_NAME,
      user_id: userId,
      latency_ms: Date.now() - context.startedAt
    });
    return jsonResponse(200, parsed);
  };
};
