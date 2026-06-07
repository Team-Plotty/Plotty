import { createPlottyApp } from "../_shared/plotty-edge/bootstrap.ts";

const FUNCTION_NAME = "plotty-api";
const jsonHeaders = { "content-type": "application/json; charset=utf-8" };

type AppHandler = (request: Request) => Promise<Response>;

let cachedHandler: AppHandler | null = null;
let bootErrorMessage: string | null = null;

const getEnv = (key: string): string | undefined => Deno.env.get(key) ?? undefined;

const resolveHandler = (): AppHandler => {
  if (cachedHandler) {
    return cachedHandler;
  }
  if (bootErrorMessage) {
    throw new Error(bootErrorMessage);
  }

  try {
    cachedHandler = createPlottyApp(getEnv);
    return cachedHandler;
  } catch (error) {
    bootErrorMessage = error instanceof Error ? error.message : String(error);
    console.error("plotty-api bootstrap failed:", bootErrorMessage);
    throw error;
  }
};

const configurationErrorResponse = (message: string): Response =>
  new Response(
    JSON.stringify({
      error: {
        code: "INTERNAL_ERROR",
        message: "Edge Function の環境変数が不足または不正です",
        detail: message
      }
    }),
    { status: 500, headers: jsonHeaders }
  );

/** Supabase 公開 URL の function 名プレフィックスを除いて router に渡す */
const stripFunctionPrefix = (pathname: string): string => {
  const prefixes = [`/${FUNCTION_NAME}`, `/functions/v1/${FUNCTION_NAME}`];
  for (const prefix of prefixes) {
    if (pathname === prefix) {
      return "/";
    }
    if (pathname.startsWith(`${prefix}/`)) {
      return pathname.slice(prefix.length);
    }
  }
  return pathname;
};

const rewriteRequestPath = (request: Request): Request => {
  const url = new URL(request.url);
  const pathname = stripFunctionPrefix(url.pathname);
  if (pathname === url.pathname) {
    return request;
  }
  const rewritten = new URL(pathname + url.search, url.origin);
  return new Request(rewritten, request);
};

Deno.serve(async (request) => {
  let handler: AppHandler;
  try {
    handler = resolveHandler();
  } catch {
    return configurationErrorResponse(bootErrorMessage ?? "bootstrap failed");
  }

  try {
    return await handler(rewriteRequestPath(request));
  } catch (error) {
    console.error("plotty-api unhandled error:", error);
    return new Response(
      JSON.stringify({
        error: {
          code: "INTERNAL_ERROR",
          message: "予期しないエラーが発生しました"
        }
      }),
      { status: 500, headers: jsonHeaders }
    );
  }
});
