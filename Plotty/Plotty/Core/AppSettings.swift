import SwiftUI

// MARK: - App Theme
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

// MARK: - App Settings
@Observable
final class AppSettings {
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let theme = "app_theme"
    }
    
    var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }
    
    init() {
        let savedTheme = defaults.string(forKey: Keys.theme) ?? AppTheme.dark.rawValue
        self.theme = AppTheme(rawValue: savedTheme) ?? .dark
    }
}

// MARK: - Environment Key
private struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings()
}

extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}
