export interface GroqUsageRepository {
  getDailyTokensUsed(userId: string, usageDateUtc: string): Promise<number>;
  addDailyTokens(userId: string, usageDateUtc: string, tokens: number): Promise<void>;
}

export const utcDateString = (date = new Date()): string => date.toISOString().slice(0, 10);
