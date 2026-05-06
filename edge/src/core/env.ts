import { z } from "zod";

const envSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  SUPABASE_JWT_ISSUER: z.string().min(1),
  SUPABASE_JWT_AUDIENCE: z.string().min(1),
  GROQ_API_KEY: z.string().min(1),
  APP_ENCRYPTION_KEY_BASE64: z.string().min(1),
  GROQ_MODEL: z.string().min(1).default("llama-3.1-70b-versatile"),
  GROQ_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  GROQ_RETRY_COUNT: z.coerce.number().int().min(0).default(1),
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(60)
});

export type EdgeEnv = z.infer<typeof envSchema>;

export const parseEdgeEnv = (source: Record<string, string | undefined>): EdgeEnv => {
  return envSchema.parse(source);
};
