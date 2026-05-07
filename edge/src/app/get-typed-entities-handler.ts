import type { JsonResponse } from "../core/http.js";
import type { EntityType } from "../contracts/chat-messages.js";
import {
  createGetEntitiesHandler,
  type GetEntitiesHandlerDeps
} from "./get-entities-handler.js";

export interface GetTypedEntitiesInput {
  authorizationHeader: string | null;
  limit?: string;
}

export const createGetTypedEntitiesHandler = (
  deps: GetEntitiesHandlerDeps,
  type: EntityType
) => {
  const baseHandler = createGetEntitiesHandler(deps);

  return async (input: GetTypedEntitiesInput): Promise<JsonResponse> => {
    return baseHandler({
      authorizationHeader: input.authorizationHeader,
      query: {
        type,
        limit: input.limit
      }
    });
  };
};
