import { createAppRouter } from "./app/router.js";
import { createAesGcmCryptoService } from "./adapters/aes-gcm-crypto.js";
import { createSupabaseGroqUsageRepository } from "./adapters/supabase-groq-usage.js";
import {
  createSupabaseClient,
  createSupabaseUserSettingsRepository
} from "./adapters/supabase-user-settings.js";
import { createSupabasePersistenceRepository } from "./adapters/supabase-persistence.js";
import { parseEdgeEnv } from "./core/env.js";
import { consoleLogger } from "./core/logger.js";
import { createSupabaseAuthVerifier } from "./services/auth.js";
import { createGroqClient } from "./services/groq-client.js";
import { createInMemoryRateLimiter } from "./services/rate-limit.js";

export type EnvGetter = (key: string) => string | undefined;

const buildEnvRecord = (get: EnvGetter): Record<string, string | undefined> => ({
  SUPABASE_URL: get("SUPABASE_URL"),
  SUPABASE_SERVICE_ROLE_KEY: get("SUPABASE_SERVICE_ROLE_KEY"),
  SUPABASE_JWT_ISSUER: get("SUPABASE_JWT_ISSUER"),
  SUPABASE_JWT_AUDIENCE: get("SUPABASE_JWT_AUDIENCE"),
  GROQ_API_KEY: get("GROQ_API_KEY"),
  APP_ENCRYPTION_KEY_BASE64: get("APP_ENCRYPTION_KEY_BASE64"),
  GROQ_MODEL: get("GROQ_MODEL"),
  GROQ_TIMEOUT_MS: get("GROQ_TIMEOUT_MS"),
  GROQ_RETRY_COUNT: get("GROQ_RETRY_COUNT"),
  RATE_LIMIT_WINDOW_MS: get("RATE_LIMIT_WINDOW_MS"),
  RATE_LIMIT_MAX_REQUESTS: get("RATE_LIMIT_MAX_REQUESTS"),
  GROQ_DAILY_TOKEN_LIMIT: get("GROQ_DAILY_TOKEN_LIMIT")
});

/** Edge / Workers / Supabase Edge Functions 共通のアプリ組み立て */
export const createPlottyApp = (getEnv: EnvGetter) => {
  const env = parseEdgeEnv(buildEnvRecord(getEnv));
  const supabase = createSupabaseClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

  return createAppRouter({
    authVerifier: createSupabaseAuthVerifier(supabase, {
      expectedIssuer: env.SUPABASE_JWT_ISSUER,
      expectedAudience: env.SUPABASE_JWT_AUDIENCE
    }),
    userSettingsRepository: createSupabaseUserSettingsRepository(supabase),
    persistenceRepository: createSupabasePersistenceRepository(supabase),
    groqUsageRepository: createSupabaseGroqUsageRepository(supabase),
    groqDailyTokenLimit: env.GROQ_DAILY_TOKEN_LIMIT,
    cryptoService: createAesGcmCryptoService(env.APP_ENCRYPTION_KEY_BASE64),
    groqClient: createGroqClient({
      apiKey: env.GROQ_API_KEY,
      model: env.GROQ_MODEL,
      timeoutMs: env.GROQ_TIMEOUT_MS,
      retries: env.GROQ_RETRY_COUNT
    }),
    rateLimiter: createInMemoryRateLimiter({
      limit: env.RATE_LIMIT_MAX_REQUESTS,
      windowMs: env.RATE_LIMIT_WINDOW_MS
    }),
    logger: consoleLogger
  });
};
