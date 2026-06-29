import Foundation
import Supabase

// MARK: - `public.users` の同期用 DTO（DB は snake_case）
private struct UserProfileRow: Decodable {
    let display_name: String?
    let timezone: String?
    let ai_persona_config: AIPersonaConfigDTO?
}

private struct AIPersonaConfigDTO: Codable {
    var name: String?
    var tone: String?
    var identity: String?
    var prohibited_topics: [String]?

    init(from config: AIPersonaConfig) {
        name = config.name
        tone = config.tone
        identity = config.identity
        prohibited_topics = config.prohibitedTopics
    }

    func resolved() -> AIPersonaConfig {
        AIPersonaConfig(
            name: name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? AIPersonaConfig.default.name,
            tone: tone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? AIPersonaConfig.default.tone,
            identity: identity?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? AIPersonaConfig.default.identity,
            prohibitedTopics: prohibited_topics ?? AIPersonaConfig.default.prohibitedTopics
        )
    }
}

private struct UserProfilePatch: Encodable {
    var display_name: String?
    var timezone: String?
    var ai_persona_config: AIPersonaConfigDTO?
}

/// `public.users` のプロフィール項目（表示名・タイムゾーン・AI 人格）。
struct PlotUserProfile: Equatable {
    var displayName: String?
    var timezoneIdentifier: String
    var aiPersona: AIPersonaConfig
}

/// `public.users` の読み書き（RLS 下で Supabase クライアントから直接 PATCH）。
enum UserProfileService {
    @MainActor
    static func fetchCurrentUserProfile() async throws -> PlotUserProfile {
        let session = try await SupabaseManager.client.auth.session
        let row: UserProfileRow = try await SupabaseManager.client
            .from("users")
            .select("display_name, timezone, ai_persona_config")
            .eq("id", value: session.user.id)
            .single()
            .execute()
            .value

        return PlotUserProfile(
            displayName: row.display_name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            timezoneIdentifier: row.timezone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? TimeZone.current.identifier,
            aiPersona: row.ai_persona_config?.resolved() ?? .default
        )
    }

    @MainActor
    static func updateProfile(
        displayName: String? = nil,
        timezoneIdentifier: String? = nil,
        aiPersona: AIPersonaConfig? = nil
    ) async throws {
        guard displayName != nil || timezoneIdentifier != nil || aiPersona != nil else { return }

        let session = try await SupabaseManager.client.auth.session
        let patch = UserProfilePatch(
            display_name: displayName.map {
                PlotInputLimits.clamp(
                    $0.trimmingCharacters(in: .whitespacesAndNewlines),
                    max: PlotInputLimits.displayName
                )
            },
            timezone: timezoneIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            ai_persona_config: aiPersona.map(AIPersonaConfigDTO.init)
        )

        try await SupabaseManager.client
            .from("users")
            .update(patch)
            .eq("id", value: session.user.id)
            .execute()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
