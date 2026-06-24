import type { SupabaseClient } from "@supabase/supabase-js";
import type { GroqUsageRepository } from "../services/groq-usage.js";

export const createSupabaseGroqUsageRepository = (
  supabase: SupabaseClient
): GroqUsageRepository => ({
  async getDailyTokensUsed(userId: string, usageDateUtc: string): Promise<number> {
    const { data, error } = await supabase
      .from("user_daily_groq_usage")
      .select("tokens_used")
      .eq("user_id", userId)
      .eq("usage_date", usageDateUtc)
      .maybeSingle();
    if (error) throw error;
    return Number(data?.tokens_used ?? 0);
  },
  async addDailyTokens(userId: string, usageDateUtc: string, tokens: number): Promise<void> {
    const current = await this.getDailyTokensUsed(userId, usageDateUtc);
    const { error } = await supabase.from("user_daily_groq_usage").upsert(
      {
        user_id: userId,
        usage_date: usageDateUtc,
        tokens_used: current + tokens
      },
      { onConflict: "user_id,usage_date" }
    );
    if (error) throw error;
  }
});

export const createInMemoryGroqUsageRepository = (): GroqUsageRepository => {
  const store = new Map<string, number>();
  const key = (userId: string, date: string) => `${userId}:${date}`;
  return {
    async getDailyTokensUsed(userId, usageDateUtc) {
      return store.get(key(userId, usageDateUtc)) ?? 0;
    },
    async addDailyTokens(userId, usageDateUtc, tokens) {
      const k = key(userId, usageDateUtc);
      store.set(k, (store.get(k) ?? 0) + tokens);
    }
  };
};
