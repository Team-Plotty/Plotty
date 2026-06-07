import type { JsonResponse } from "../core/http.ts";
import type { EntityType } from "../contracts/chat-messages.ts";
import {
  createGetEntitiesHandler,
  type GetEntitiesHandlerDeps
} from "./get-entities-handler.ts";

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
