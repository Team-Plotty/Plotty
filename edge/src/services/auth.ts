import { z } from "zod";
import type { SupabaseClient } from "@supabase/supabase-js";

const jwtPayloadSchema = z.object({
  sub: z.string().uuid(),
  aud: z.union([z.string(), z.array(z.string())]).optional(),
  iss: z.string().optional()
});

export interface AuthVerifier {
  verifyAccessToken(token: string): Promise<{ userId: string }>;
}

export interface JwtValidationOptions {
  expectedAudience?: string;
  expectedIssuer?: string;
}

export const parseBearerToken = (authorizationHeader: string | null): string | null => {
  if (!authorizationHeader) {
    return null;
  }

  const [scheme, token] = authorizationHeader.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) {
    return null;
  }

  return token;
};

const decodeJwtPayload = (token: string): z.infer<typeof jwtPayloadSchema> => {
  const [, payloadSegment] = token.split(".");
  if (!payloadSegment) {
    throw new Error("Invalid token");
  }

  const payloadJson = atob(payloadSegment.replace(/-/g, "+").replace(/_/g, "/"));
  const parsed = jwtPayloadSchema.safeParse(JSON.parse(payloadJson));
  if (!parsed.success) {
    throw new Error("Invalid token payload");
  }
  return parsed.data;
};

const assertJwtClaims = (
  payload: z.infer<typeof jwtPayloadSchema>,
  options?: JwtValidationOptions
): void => {
  if (options?.expectedIssuer && payload.iss !== options.expectedIssuer) {
    throw new Error("Invalid token issuer");
  }

  if (options?.expectedAudience) {
    const aud = payload.aud;
    if (typeof aud === "string" && aud !== options.expectedAudience) {
      throw new Error("Invalid token audience");
    }
    if (Array.isArray(aud) && !aud.includes(options.expectedAudience)) {
      throw new Error("Invalid token audience");
    }
    if (!aud) {
      throw new Error("Invalid token audience");
    }
  }
};

export const createJwtPayloadVerifier = (options?: JwtValidationOptions): AuthVerifier => ({
  async verifyAccessToken(token: string): Promise<{ userId: string }> {
    const payload = decodeJwtPayload(token);
    assertJwtClaims(payload, options);
    return { userId: payload.sub };
  }
});

export const createSupabaseAuthVerifier = (
  supabase: SupabaseClient,
  options?: JwtValidationOptions
): AuthVerifier => ({
  async verifyAccessToken(token: string): Promise<{ userId: string }> {
    const payload = decodeJwtPayload(token);
    assertJwtClaims(payload, options);

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user?.id) {
      throw new Error("Invalid token");
    }

    const parsed = z.string().uuid().safeParse(data.user.id);
    if (!parsed.success) {
      throw new Error("Invalid token payload");
    }
    return { userId: parsed.data };
  }
});
