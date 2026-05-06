import { createAppRouter } from "./app/router.js";
import { createSimpleCryptoService } from "./adapters/simple-crypto.js";
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

const env = parseEdgeEnv({
  SUPABASE_URL: process.env.SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
  GROQ_API_KEY: process.env.GROQ_API_KEY,
  GROQ_MODEL: process.env.GROQ_MODEL,
  GROQ_TIMEOUT_MS: process.env.GROQ_TIMEOUT_MS,
  GROQ_RETRY_COUNT: process.env.GROQ_RETRY_COUNT,
  RATE_LIMIT_WINDOW_MS: process.env.RATE_LIMIT_WINDOW_MS,
  RATE_LIMIT_MAX_REQUESTS: process.env.RATE_LIMIT_MAX_REQUESTS
});

const supabase = createSupabaseClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
const app = createAppRouter({
  authVerifier: createSupabaseAuthVerifier(supabase),
  userSettingsRepository: createSupabaseUserSettingsRepository(supabase),
  persistenceRepository: createSupabasePersistenceRepository(supabase),
  cryptoService: createSimpleCryptoService(),
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

export default {
  fetch: app
};
