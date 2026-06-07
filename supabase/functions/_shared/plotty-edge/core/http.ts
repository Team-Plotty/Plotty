export interface JsonResponse {
  status: number;
  body: unknown;
}

export const jsonResponse = (status: number, body: unknown): JsonResponse => ({
  status,
  body
});
