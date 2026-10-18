export class GroqHttpError extends Error {
  readonly status: number;

  constructor(status: number) {
    super(`Groq API error: ${status}`);
    this.name = "GroqHttpError";
    this.status = status;
  }
}

export class GroqEmptyError extends Error {
  constructor() {
    super("Groq response content is empty");
    this.name = "GroqEmptyError";
  }
}

export class GroqSchemaError extends Error {
  constructor() {
    super("Groq response schema validation failed");
    this.name = "GroqSchemaError";
  }
}

export const isGroqError = (error: unknown): boolean =>
  error instanceof GroqHttpError ||
  error instanceof GroqEmptyError ||
  error instanceof GroqSchemaError ||
  (error instanceof Error && error.name === "AbortError");

type GroqFailureCode = "GROQ_TIMEOUT" | "GROQ_UNAVAILABLE" | "GROQ_CONFIG_ERROR" | "INTERNAL_ERROR";

/** 待てば回復する失敗（429・5xx）と、設定を直すまで失敗し続けるもの（キー不正・モデル提供終了などの 4xx）を分ける */
const isRetryableGroqStatus = (status: number): boolean => status === 429 || status >= 500;

export const mapGroqErrorToCode = (error: unknown): GroqFailureCode => {
  if (error instanceof Error && error.name === "AbortError") {
    return "GROQ_TIMEOUT";
  }
  if (error instanceof GroqSchemaError) {
    return "INTERNAL_ERROR";
  }
  if (error instanceof GroqHttpError && !isRetryableGroqStatus(error.status)) {
    return "GROQ_CONFIG_ERROR";
  }
  return "GROQ_UNAVAILABLE";
};

export const mapRequestErrorToCode = (error: unknown): GroqFailureCode => {
  if (!isGroqError(error)) {
    return "INTERNAL_ERROR";
  }
  return mapGroqErrorToCode(error);
};
