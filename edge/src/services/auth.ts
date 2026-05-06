import { z } from "zod";

const jwtPayloadSchema = z.object({
  sub: z.string().uuid()
});

export interface AuthVerifier {
  verifyAccessToken(token: string): Promise<{ userId: string }>;
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

export const createJwtPayloadVerifier = (): AuthVerifier => ({
  async verifyAccessToken(token: string): Promise<{ userId: string }> {
    const [, payloadSegment] = token.split(".");
    if (!payloadSegment) {
      throw new Error("Invalid token");
    }

    const payloadJson = atob(payloadSegment.replace(/-/g, "+").replace(/_/g, "/"));
    const parsed = jwtPayloadSchema.safeParse(JSON.parse(payloadJson));
    if (!parsed.success) {
      throw new Error("Invalid token payload");
    }

    return { userId: parsed.data.sub };
  }
});
