import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { UserSettings, UserSettingsRepository } from "../services/user-settings.js";

interface UsersRow {
  timezone: string | null;
  ai_persona_config: {
    name?: string;
    tone?: string;
    identity?: string;
    prohibited_topics?: string[];
  } | null;
}

export const createSupabaseClient = (url: string, serviceRoleKey: string): SupabaseClient => {
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false }
  });
};

export const createSupabaseUserSettingsRepository = (
  supabase: SupabaseClient
): UserSettingsRepository => ({
  async findByUserId(userId: string): Promise<UserSettings | null> {
    const { data, error } = await supabase
      .from("users")
      .select("timezone, ai_persona_config")
      .eq("id", userId)
      .single<UsersRow>();

    if (error || !data) {
      return null;
    }

    return {
      timezone: data.timezone ?? "UTC",
      aiPersonaConfig: {
        name: data.ai_persona_config?.name ?? "Plotty",
        tone: data.ai_persona_config?.tone ?? "friendly",
        identity: data.ai_persona_config?.identity ?? "優秀な秘書",
        prohibited_topics: data.ai_persona_config?.prohibited_topics ?? []
      }
    };
  }
});
