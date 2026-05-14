import SwiftUI

// MARK: - 基本フォント（プレビュー等。本番 UI は `scaled*` のセマンティックフォント推奨）
extension Font {
    static let displayLarge = Font.system(.largeTitle, design: .default, weight: .bold)
    static let displayMedium = Font.system(.title, design: .default, weight: .bold)
    static let titleLarge = Font.system(.title2, design: .default, weight: .semibold)
    static let titleMedium = Font.system(.title3, design: .default, weight: .semibold)
    static let titleSmall = Font.system(.callout, design: .default, weight: .medium)
    static let bodyLarge = Font.system(.body, design: .default, weight: .regular)
    static let bodyMedium = Font.system(.subheadline, design: .default, weight: .regular)
    static let bodySmall = Font.system(.footnote, design: .default, weight: .regular)
    static let labelMedium = Font.system(.footnote, design: .default, weight: .medium)
    static let caption = Font.system(.caption, design: .default, weight: .semibold)
    static let micro = Font.system(.caption2, design: .default, weight: .semibold)
}

// MARK: - 文字サイズ可変（テキストスタイルでダイナミックタイプに追従。UIKit は使わない）
extension Font {
    static func scaledDisplayLarge() -> Font {
        .system(.largeTitle, design: .default, weight: .bold)
    }
    
    static func scaledDisplayMedium() -> Font {
        .system(.title, design: .default, weight: .bold)
    }
    
    static func scaledTitleLarge() -> Font {
        .system(.title2, design: .default, weight: .semibold)
    }
    
    static func scaledTitleMedium() -> Font {
        .system(.title3, design: .default, weight: .semibold)
    }
    
    static func scaledTitleSmall() -> Font {
        .system(.callout, design: .default, weight: .medium)
    }
    
    static func scaledBodyLarge() -> Font {
        .system(.body, design: .default, weight: .regular)
    }
    
    static func scaledBodyMedium() -> Font {
        .system(.subheadline, design: .default, weight: .regular)
    }
    
    static func scaledBodySmall() -> Font {
        .system(.footnote, design: .default, weight: .regular)
    }
    
    static func scaledLabelMedium() -> Font {
        .system(.footnote, design: .default, weight: .medium)
    }
    
    static func scaledCaption() -> Font {
        .system(.caption, design: .default, weight: .semibold)
    }
    
    static func scaledMicro() -> Font {
        .system(.caption2, design: .default, weight: .semibold)
    }
}

// MARK: - テキスト用の細かい装飾
extension View {
    func titleTracking() -> some View {
        self.tracking(-0.3)
    }
    
    func bodyLineSpacing() -> some View {
        self.lineSpacing(4)
    }
}
