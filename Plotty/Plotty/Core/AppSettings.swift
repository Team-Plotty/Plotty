import SwiftUI

// MARK: - 外観テーマ（ライト / ダーク / システム）
enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "システム設定に従う"
        case .light: return "ライトモード"
        case .dark: return "ダークモード"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - AI 人格設定（`ai_persona_config` 相当）
struct AIPersonaConfig: Codable, Equatable {
    var name: String
    var tone: String
    var identity: String
    var prohibitedTopics: [String]
    
    static let `default` = AIPersonaConfig(
        name: "Plotty",
        tone: "friendly",
        identity: "優秀な秘書",
        prohibitedTopics: ["politics", "religion"]
    )
}

// MARK: - アプリ設定（テーマ・タイムゾーン・AI人格）
@Observable
final class AppSettings {
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let theme = "app_theme"
        static let timezone = "app_timezone"
        static let aiPersona = "app_ai_persona"
    }
    
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    
    var timezoneIdentifier: String {
        didSet { defaults.set(timezoneIdentifier, forKey: Keys.timezone) }
    }
    
    var aiPersona: AIPersonaConfig {
        didSet {
            if let data = try? JSONEncoder().encode(aiPersona) {
                defaults.set(data, forKey: Keys.aiPersona)
            }
        }
    }
    
    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }
    
    init() {
        let savedTheme = defaults.string(forKey: Keys.theme) ?? AppTheme.dark.rawValue
        self.theme = AppTheme(rawValue: savedTheme) ?? .dark
        self.timezoneIdentifier = defaults.string(forKey: Keys.timezone)
            ?? TimeZone.current.identifier
        if let data = defaults.data(forKey: Keys.aiPersona),
           let decoded = try? JSONDecoder().decode(AIPersonaConfig.self, from: data) {
            self.aiPersona = decoded
        } else {
            self.aiPersona = .default
        }
    }
}

// MARK: - SwiftUI 環境値への登録
private struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings()
}

extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}
