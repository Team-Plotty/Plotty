export interface LogFields {
  request_id: string;
  user_id?: string;
  function_name: string;
  latency_ms?: number;
  error_code?: string;
  [key: string]: unknown;
}

export interface Logger {
  info(message: string, fields: LogFields): void;
  error(message: string, fields: LogFields): void;
}

export const consoleLogger: Logger = {
  info(message, fields) {
    console.info(
      JSON.stringify({
        level: "info",
        message,
        timestamp: new Date().toISOString(),
        ...fields
      })
    );
  },
  error(message, fields) {
    console.error(
      JSON.stringify({
        level: "error",
        message,
        timestamp: new Date().toISOString(),
        ...fields
      })
    );
  }
};
