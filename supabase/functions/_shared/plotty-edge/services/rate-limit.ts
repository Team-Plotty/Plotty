export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
}

export interface RateLimiter {
  consume(key: string): Promise<RateLimitResult>;
}

export interface InMemoryRateLimiterOptions {
  limit: number;
  windowMs: number;
}

interface Bucket {
  count: number;
  windowStart: number;
}

export const createInMemoryRateLimiter = (
  options: InMemoryRateLimiterOptions
): RateLimiter => {
  const buckets = new Map<string, Bucket>();

  return {
    async consume(key: string): Promise<RateLimitResult> {
      const now = Date.now();
      const bucket = buckets.get(key);
      if (!bucket || now - bucket.windowStart >= options.windowMs) {
        buckets.set(key, { count: 1, windowStart: now });
        return { allowed: true, remaining: options.limit - 1 };
      }

      if (bucket.count >= options.limit) {
        return { allowed: false, remaining: 0 };
      }

      bucket.count += 1;
      return { allowed: true, remaining: options.limit - bucket.count };
    }
  };
};
