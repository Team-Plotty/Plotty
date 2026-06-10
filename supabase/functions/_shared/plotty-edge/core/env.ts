import { z } from "zod";

const envSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  SUPABASE_JWT_ISSUER: z.string().min(1),
  SUPABASE_JWT_AUDIENCE: z.string().min(1),
  GROQ_API_KEY: z.string().min(1),
  APP_ENCRYPTION_KEY_BASE64: z.string().min(1),
  GROQ_MODEL: z.string().min(1).default("llama-3.3-70b-versatile"),
  GROQ_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  GROQ_RETRY_COUNT: z.coerce.number().int().min(0).default(1),
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(60),
  GROQ_DAILY_TOKEN_LIMIT: z.coerce.number().int().positive().default(50000)
});

export type EdgeEnv = z.infer<typeof envSchema>;

/** Supabase Edge Functions では JWT issuer / audience が Secrets に無いことがあるため補完する */
export const normalizeEdgeEnvSource = (
  source: Record<string, string | undefined>
): Record<string, string | undefined> => {
  const supabaseUrl = source.SUPABASE_URL?.replace(/\/$/, "");
  return {
    ...source,
    SUPABASE_URL: supabaseUrl,
    SUPABASE_JWT_ISSUER:
      source.SUPABASE_JWT_ISSUER ??
      (supabaseUrl ? `${supabaseUrl}/auth/v1` : undefined),
    SUPABASE_JWT_AUDIENCE: source.SUPABASE_JWT_AUDIENCE ?? "authenticated"
  };
};

export const parseEdgeEnv = (source: Record<string, string | undefined>): EdgeEnv => {
  return envSchema.parse(normalizeEdgeEnvSource(source));
};
