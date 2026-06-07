import {
  createChatMessagesHandler,
  type ChatMessagesHandlerDeps
} from "./chat-messages-handler.ts";
import {
  createDeleteEntityHandler,
  type DeleteEntityHandlerDeps
} from "./delete-entity-handler.ts";
import {
  createGetEntitiesHandler,
  type GetEntitiesHandlerDeps
} from "./get-entities-handler.ts";
import {
  createPatchEntityHandler,
  type PatchEntityHandlerDeps
} from "./patch-entity-handler.ts";

type RouterDeps = ChatMessagesHandlerDeps &
  GetEntitiesHandlerDeps &
  PatchEntityHandlerDeps &
  DeleteEntityHandlerDeps;

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8"
};

const parseBody = async (request: Request): Promise<unknown> => {
  const text = await request.text();
  if (!text) {
    return {};
  }
  return JSON.parse(text);
};

const extractPatchRoute = (pathname: string): { type: "schedule" | "task" | "memo"; id: string } | null => {
  const parts = pathname.split("/").filter(Boolean);
  if (parts.length !== 4 || parts[0] !== "api" || parts[1] !== "v1") {
    return null;
  }

  if (
    ["schedules", "tasks", "memos"].includes(parts[2]) &&
    parts[3] &&
    /^[0-9a-fA-F-]{36}$/.test(parts[3])
  ) {
    const type = parts[2] === "schedules" ? "schedule" : parts[2] === "tasks" ? "task" : "memo";
    return { type, id: parts[3] };
  }
  return null;
};

const extractDeleteRoute = (pathname: string): { type: "schedule" | "task" | "memo"; id: string } | null => {
  const parts = pathname.split("/").filter(Boolean);
  if (parts.length !== 5 || parts[0] !== "api" || parts[1] !== "v1" || parts[2] !== "entities") {
    return null;
  }
  if (!["schedule", "task", "memo"].includes(parts[3])) {
    return null;
  }
  if (!/^[0-9a-fA-F-]{36}$/.test(parts[4])) {
    return null;
  }
  return { type: parts[3] as "schedule" | "task" | "memo", id: parts[4] };
};

export const createAppRouter = (deps: RouterDeps) => {
  const chatHandler = createChatMessagesHandler(deps);
  const getEntitiesHandler = createGetEntitiesHandler(deps);
  const patchEntityHandler = createPatchEntityHandler(deps);
  const deleteEntityHandler = createDeleteEntityHandler(deps);

  return async (request: Request): Promise<Response> => {
    const url = new URL(request.url);
    const authorizationHeader = request.headers.get("authorization");

    if (request.method === "POST" && url.pathname === "/api/v1/chat/messages") {
      const result = await chatHandler({
        authorizationHeader,
        body: await parseBody(request)
      });
      return new Response(JSON.stringify(result.body), {
        status: result.status,
        headers: jsonHeaders
      });
    }

    if (request.method === "GET" && url.pathname === "/api/v1/entities") {
      const result = await getEntitiesHandler({
        authorizationHeader,
        query: {
          type: url.searchParams.get("type") ?? undefined,
          limit: url.searchParams.get("limit") ?? undefined
        }
      });
      return new Response(JSON.stringify(result.body), {
        status: result.status,
        headers: jsonHeaders
      });
    }

    const patchRoute = extractPatchRoute(url.pathname);
    if (patchRoute && request.method === "PATCH") {
      const result = await patchEntityHandler({
        authorizationHeader,
        type: patchRoute.type,
        id: patchRoute.id,
        body: await parseBody(request)
      });
      return new Response(JSON.stringify(result.body), {
        status: result.status,
        headers: jsonHeaders
      });
    }

    const deleteRoute = extractDeleteRoute(url.pathname);
    if (deleteRoute && request.method === "DELETE") {
      const result = await deleteEntityHandler({
        authorizationHeader,
        type: deleteRoute.type,
        id: deleteRoute.id
      });
      return new Response(JSON.stringify(result.body), {
        status: result.status,
        headers: jsonHeaders
      });
    }

    return new Response(
      JSON.stringify({
        error: {
          code: "NOT_FOUND",
          message: "エンドポイントが見つかりません"
        }
      }),
      { status: 404, headers: jsonHeaders }
    );
  };
};
