export interface RequestContext {
  requestId: string;
  startedAt: number;
}

export const createRequestContext = (): RequestContext => ({
  requestId: crypto.randomUUID(),
  startedAt: Date.now()
});
