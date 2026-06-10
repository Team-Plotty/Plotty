import { z } from "zod";

export const errorCodeSchema = z.enum([
  "VALIDATION_ERROR",
  "UNAUTHORIZED",
  "FORBIDDEN",
  "NOT_FOUND",
  "CONFLICT",
  "GROQ_TIMEOUT",
  "GROQ_UNAVAILABLE",
  "RATE_LIMITED",
  "INTERNAL_ERROR"
]);

export type ErrorCode = z.infer<typeof errorCodeSchema>;

export const errorResponseSchema = z.object({
  error: z.object({
    code: errorCodeSchema,
    message: z.string().min(1),
    request_id: z.string().min(1).optional()
  })
});

export type ErrorResponse = z.infer<typeof errorResponseSchema>;

export const errorMessageByCode: Record<ErrorCode, string> = {
  VALIDATION_ERROR: "入力内容を確認して再度お試しください",
  UNAUTHORIZED: "ログイン状態を確認してください",
  FORBIDDEN: "この操作を実行する権限がありません",
  NOT_FOUND: "対象データが見つかりませんでした",
  CONFLICT: "同時更新が発生しました。再取得してお試しください",
  GROQ_TIMEOUT: "通信状況を確認して再度お試しください",
  GROQ_UNAVAILABLE: "AIサービスが混み合っています。少し待って再試行してください",
  RATE_LIMITED: "リクエストが多すぎます。時間をおいて再試行してください",
  INTERNAL_ERROR: "予期しないエラーが発生しました。時間をおいて再試行してください",
};
