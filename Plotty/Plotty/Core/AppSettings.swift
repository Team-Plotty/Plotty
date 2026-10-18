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

// MARK: - 表示言語（日本語 / 英語）
/// 設定から言語を選ぶ機能は廃止し、アプリは日本語に固定している。英語の書式分岐は各所に残っている
enum AppLanguage: String, CaseIterable {
    case japanese = "ja"
    case english = "en"
    
    /// `@hours=h23` で DatePicker などシステム部品の時刻も 24 時間表記にする（端末の 12/24 時間設定に左右されない）
    var locale: Locale {
        switch self {
        case .japanese: return Locale(identifier: "ja_JP@hours=h23")
        case .english: return Locale(identifier: "en_US@hours=h23")
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

// MARK: - アプリ設定（テーマ・AI人格）
/// タイムゾーンは設定項目を持たず端末のものを使う（サーバーへの反映は `UserSettingsSync`）
@Observable
final class AppSettings {
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let theme = "app_theme"
        static let aiPersona = "app_ai_persona"
    }
    
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    
    /// 以前に English を選んだ端末でも日本語に戻すため、保存済みの値は読まない
    let language: AppLanguage = .japanese
    
    var aiPersona: AIPersonaConfig {
        didSet {
            if let data = try? JSONEncoder().encode(aiPersona) {
                defaults.set(data, forKey: Keys.aiPersona)
            }
        }
    }

    /// クラウドから取得した値を端末へ反映する（`public.users` 同期用）。
    func applyRemoteProfile(aiPersona: AIPersonaConfig?) {
        if let aiPersona {
            self.aiPersona = aiPersona
        }
    }
    
    init() {
        let savedTheme = defaults.string(forKey: Keys.theme) ?? AppTheme.dark.rawValue
        self.theme = AppTheme(rawValue: savedTheme) ?? .dark
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
