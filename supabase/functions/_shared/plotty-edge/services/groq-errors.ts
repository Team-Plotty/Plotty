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

export const mapGroqErrorToCode = (
  error: unknown
): "GROQ_TIMEOUT" | "GROQ_UNAVAILABLE" | "INTERNAL_ERROR" => {
  if (error instanceof Error && error.name === "AbortError") {
    return "GROQ_TIMEOUT";
  }
  if (error instanceof GroqSchemaError) {
    return "INTERNAL_ERROR";
  }
  return "GROQ_UNAVAILABLE";
};

export const mapRequestErrorToCode = (
  error: unknown
): "GROQ_TIMEOUT" | "GROQ_UNAVAILABLE" | "INTERNAL_ERROR" => {
  if (!isGroqError(error)) {
    return "INTERNAL_ERROR";
  }
  return mapGroqErrorToCode(error);
};
