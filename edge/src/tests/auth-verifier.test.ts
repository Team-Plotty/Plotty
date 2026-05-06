import test from "node:test";
import assert from "node:assert/strict";
import { createJwtPayloadVerifier } from "../services/auth.js";

const toBase64Url = (value: string): string => {
  return Buffer.from(value, "utf-8")
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
};

const createTestToken = (payload: Record<string, unknown>): string => {
  const header = toBase64Url(JSON.stringify({ alg: "none", typ: "JWT" }));
  const body = toBase64Url(JSON.stringify(payload));
  return `${header}.${body}.`;
};

test("jwt verifier passes when audience and issuer match", async () => {
  const verifier = createJwtPayloadVerifier({
    expectedAudience: "authenticated",
    expectedIssuer: "https://example.supabase.co/auth/v1"
  });

  const token = createTestToken({
    sub: "11111111-1111-1111-1111-111111111111",
    aud: "authenticated",
    iss: "https://example.supabase.co/auth/v1"
  });

  const result = await verifier.verifyAccessToken(token);
  assert.equal(result.userId, "11111111-1111-1111-1111-111111111111");
});

test("jwt verifier rejects when audience does not match", async () => {
  const verifier = createJwtPayloadVerifier({
    expectedAudience: "authenticated",
    expectedIssuer: "https://example.supabase.co/auth/v1"
  });

  const token = createTestToken({
    sub: "11111111-1111-1111-1111-111111111111",
    aud: "public",
    iss: "https://example.supabase.co/auth/v1"
  });

  await assert.rejects(() => verifier.verifyAccessToken(token), /Invalid token audience/);
});
