export interface RetryOptions {
  retries: number;
}

export const withRetry = async <T>(
  operation: (attempt: number) => Promise<T>,
  options: RetryOptions
): Promise<T> => {
  let lastError: unknown;

  for (let attempt = 0; attempt <= options.retries; attempt += 1) {
    try {
      return await operation(attempt);
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError;
};
