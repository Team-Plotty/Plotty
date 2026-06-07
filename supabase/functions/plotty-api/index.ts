import { createPlottyApp } from "../_shared/plotty-edge/bootstrap.ts";

const FUNCTION_NAME = "plotty-api";
const handler = createPlottyApp((key) => Deno.env.get(key) ?? undefined);

/** Supabase 公開 URL の `/functions/v1/plotty-api` プレフィックスを除いて router に渡す */
const stripFunctionPrefix = (pathname: string): string => {
  const prefix = `/${FUNCTION_NAME}`;
  if (pathname === prefix) {
    return "/";
  }
  if (pathname.startsWith(`${prefix}/`)) {
    return pathname.slice(prefix.length);
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

Deno.serve((request) => handler(rewriteRequestPath(request)));
