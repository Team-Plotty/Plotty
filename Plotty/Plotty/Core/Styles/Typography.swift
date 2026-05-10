import SwiftUI

// MARK: - Typography (Apple HIG Compliant)
extension Font {
    static let displayLarge = Font.system(size: 34, weight: .bold)
    static let displayMedium = Font.system(size: 28, weight: .bold)
    static let titleLarge = Font.system(size: 22, weight: .semibold)
    static let titleMedium = Font.system(size: 18, weight: .semibold)
    static let titleSmall = Font.system(size: 16, weight: .medium)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    static let labelMedium = Font.system(size: 13, weight: .medium)
    static let caption = Font.system(size: 11, weight: .semibold)
    static let micro = Font.system(size: 10, weight: .semibold)
}

// MARK: - Scaled Fonts (Dynamic Type Support)
extension Font {
    static func scaledDisplayLarge() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 34), weight: .bold)
    }
    
    static func scaledDisplayMedium() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 28), weight: .bold)
    }
    
    static func scaledTitleLarge() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 22), weight: .semibold)
    }
    
    static func scaledTitleMedium() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 18), weight: .semibold)
    }
    
    static func scaledTitleSmall() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 16), weight: .medium)
    }
    
    static func scaledBodyLarge() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 17), weight: .regular)
    }
    
    static func scaledBodyMedium() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 15), weight: .regular)
    }
    
    static func scaledBodySmall() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 13), weight: .regular)
    }
    
    static func scaledLabelMedium() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 13), weight: .medium)
    }
    
    static func scaledCaption() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 11), weight: .semibold)
    }
    
    static func scaledMicro() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 10), weight: .semibold)
    }
}

// MARK: - Text Modifiers
extension View {
    func titleTracking() -> some View {
        self.tracking(-0.3)
    }
    
    func bodyLineSpacing() -> some View {
        self.lineSpacing(4)
    }
}
