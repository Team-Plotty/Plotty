export interface UserSettings {
  timezone: string;
  aiPersonaConfig: {
    name: string;
    tone: string;
    identity: string;
    prohibited_topics: string[];
  };
}

export interface UserSettingsRepository {
  findByUserId(userId: string): Promise<UserSettings | null>;
}
