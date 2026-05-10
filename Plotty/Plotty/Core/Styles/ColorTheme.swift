import SwiftUI

// MARK: - Dark Mode (Warm Charcoal)
extension Color {
    // Base
    static let darkBase = Color(hex: "#0F0E0D")
    static let darkSurface = Color(hex: "#141210")
    
    // Glass layers
    static let darkGlassHeavy = Color.white.opacity(0.14)
    static let darkGlassMid = Color.white.opacity(0.07)
    static let darkGlassLight = Color.white.opacity(0.04)
    
    // Border
    static let darkBorderStrong = Color(hex: "#FFFCF8").opacity(0.22)
    static let darkBorderDefault = Color(hex: "#FFFCF8").opacity(0.11)
    static let darkBorderSubtle = Color(hex: "#FFFCF8").opacity(0.07)
    
    // Text
    static let darkTextPrimary = Color(hex: "#FFFCF8").opacity(0.92)
    static let darkTextSecondary = Color(hex: "#FFFCF8").opacity(0.55)
    static let darkTextTertiary = Color(hex: "#FFFCF8").opacity(0.33)
    static let darkTextDisabled = Color(hex: "#FFFCF8").opacity(0.20)
    
    // Chat specific
    static let darkTextUser = Color(hex: "#FFFCF8").opacity(0.92)
    static let darkTextAI = Color(hex: "#FFFCF8").opacity(0.52)
    static let darkAILine = Color(hex: "#FFFCF8").opacity(0.20)
    
    // Input bar
    static let darkInputBG = Color(hex: "#191613").opacity(0.80)
}

// MARK: - Light Mode (Warm Paper)
extension Color {
    // Base
    static let lightBase = Color(hex: "#F8F6F2")
    static let lightSurface = Color(hex: "#F3F1EC")
    
    // Glass layers
    static let lightGlassHeavy = Color.black.opacity(0.09)
    static let lightGlassMid = Color.black.opacity(0.045)
    static let lightGlassLight = Color.black.opacity(0.025)
    
    // Border
    static let lightBorderStrong = Color.black.opacity(0.13)
    static let lightBorderDefault = Color.black.opacity(0.08)
    static let lightBorderSubtle = Color.black.opacity(0.05)
    
    // Text
    static let lightTextPrimary = Color.black.opacity(0.85)
    static let lightTextSecondary = Color.black.opacity(0.50)
    static let lightTextTertiary = Color.black.opacity(0.33)
    static let lightTextDisabled = Color.black.opacity(0.18)
    
    // Chat specific
    static let lightTextUser = Color.black.opacity(0.85)
    static let lightTextAI = Color.black.opacity(0.48)
    static let lightAILine = Color.black.opacity(0.16)
    
    // Input bar
    static let lightInputBG = Color(hex: "#F8F5F0").opacity(0.88)
}

// MARK: - Semantic Colors (Environment-aware)
struct AppColors {
    @Environment(\.colorScheme) private var colorScheme
    
    var base: Color {
        colorScheme == .dark ? .darkBase : .lightBase
    }
    
    var surface: Color {
        colorScheme == .dark ? .darkSurface : .lightSurface
    }
    
    var glassHeavy: Color {
        colorScheme == .dark ? .darkGlassHeavy : .lightGlassHeavy
    }
    
    var glassMid: Color {
        colorScheme == .dark ? .darkGlassMid : .lightGlassMid
    }
    
    var glassLight: Color {
        colorScheme == .dark ? .darkGlassLight : .lightGlassLight
    }
    
    var borderStrong: Color {
        colorScheme == .dark ? .darkBorderStrong : .lightBorderStrong
    }
    
    var borderDefault: Color {
        colorScheme == .dark ? .darkBorderDefault : .lightBorderDefault
    }
    
    var borderSubtle: Color {
        colorScheme == .dark ? .darkBorderSubtle : .lightBorderSubtle
    }
    
    var textPrimary: Color {
        colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary
    }
    
    var textSecondary: Color {
        colorScheme == .dark ? .darkTextSecondary : .lightTextSecondary
    }
    
    var textTertiary: Color {
        colorScheme == .dark ? .darkTextTertiary : .lightTextTertiary
    }
    
    var textDisabled: Color {
        colorScheme == .dark ? .darkTextDisabled : .lightTextDisabled
    }
    
    var textUser: Color {
        colorScheme == .dark ? .darkTextUser : .lightTextUser
    }
    
    var textAI: Color {
        colorScheme == .dark ? .darkTextAI : .lightTextAI
    }
    
    var aiLine: Color {
        colorScheme == .dark ? .darkAILine : .lightAILine
    }
    
    var inputBG: Color {
        colorScheme == .dark ? .darkInputBG : .lightInputBG
    }
}

// MARK: - Environment Key
private struct AppColorsKey: EnvironmentKey {
    static let defaultValue = AppColors()
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}
