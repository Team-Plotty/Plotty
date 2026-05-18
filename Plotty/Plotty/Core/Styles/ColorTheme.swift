import SwiftUI

// MARK: - ダークモード用カラー（暖かみのあるチャコール系）
extension Color {
    // ベース背景・面の色（近黒は避ける。メッシュのぼかしと合成しても「真っ黒」に見えない程度まで明るめ）
    static let darkBase = Color(hex: "#38342F")
    static let darkSurface = Color(hex: "#423E38")
    
    // ガラスレイヤー用の白の不透明度プリセット
    static let darkGlassHeavy = Color.white.opacity(0.14)
    static let darkGlassMid = Color.white.opacity(0.07)
    static let darkGlassLight = Color.white.opacity(0.04)
    
    // 枠線の強さ
    static let darkBorderStrong = Color(hex: "#FFFCF8").opacity(0.22)
    static let darkBorderDefault = Color(hex: "#FFFCF8").opacity(0.11)
    static let darkBorderSubtle = Color(hex: "#FFFCF8").opacity(0.07)
    
    // 本文・ラベル用テキスト色
    static let darkTextPrimary = Color(hex: "#FFFCF8").opacity(0.92)
    static let darkTextSecondary = Color(hex: "#FFFCF8").opacity(0.55)
    static let darkTextTertiary = Color(hex: "#FFFCF8").opacity(0.33)
    static let darkTextDisabled = Color(hex: "#FFFCF8").opacity(0.20)
    
    /// AI 応答待ちの画面枠グロー（Gemini 風の青）
    static let plotAIBorderGlow = Color(hex: "#5EB3FF")
    
    // チャット画面専用のテキスト・区切り線
    static let darkTextUser = Color(hex: "#FFFCF8").opacity(0.92)
    static let darkTextAI = Color(hex: "#FFFCF8").opacity(0.52)
    static let darkAILine = Color(hex: "#FFFCF8").opacity(0.20)
    
    // 入力バー背景
    static let darkInputBG = Color(hex: "#3D3935").opacity(0.88)
    
    /// 検索・入力のプレースホルダ（ガラス上でも読めるコントラスト）
    static let darkInputPlaceholder = Color(hex: "#FFFCF8").opacity(0.72)
}

// MARK: - ライトモード用カラー（暖かみのあるペーパー系）
extension Color {
    /// `AmbientBackground` の下地と同じ色。ステータス付近のシステム帯をこの色で塗りつぶすときに使う。
    static let lightAmbientBase = Color(hex: "#E8E4DC")
    
    // ベース背景・面の色
    static let lightBase = Color(hex: "#F8F6F2")
    static let lightSurface = Color(hex: "#F3F1EC")
    
    // ガラスレイヤー用の黒の不透明度プリセット
    static let lightGlassHeavy = Color.black.opacity(0.09)
    static let lightGlassMid = Color.black.opacity(0.045)
    static let lightGlassLight = Color.black.opacity(0.025)
    
    // 枠線の強さ
    static let lightBorderStrong = Color.black.opacity(0.13)
    static let lightBorderDefault = Color.black.opacity(0.08)
    static let lightBorderSubtle = Color.black.opacity(0.05)
    
    // 本文・ラベル用テキスト色
    static let lightTextPrimary = Color.black.opacity(0.85)
    static let lightTextSecondary = Color.black.opacity(0.50)
    static let lightTextTertiary = Color.black.opacity(0.33)
    static let lightTextDisabled = Color.black.opacity(0.18)
    
    // チャット画面専用のテキスト・区切り線
    static let lightTextUser = Color.black.opacity(0.85)
    static let lightTextAI = Color.black.opacity(0.48)
    static let lightAILine = Color.black.opacity(0.16)
    
    // 入力バー背景
    static let lightInputBG = Color(hex: "#F8F5F0").opacity(0.88)
    
    /// 検索・入力のプレースホルダ（ガラス上でも読めるコントラスト）
    static let lightInputPlaceholder = Color.black.opacity(0.42)
}

// MARK: - 外観モードに応じて色を切り替えるラッパー
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

// MARK: - SwiftUI 環境に `AppColors` を載せるためのキー
private struct AppColorsKey: EnvironmentKey {
    static let defaultValue = AppColors()
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}

// MARK: - アプリ外観の実効カラースキーム（`glassEffect` 内でも親の値を使う）
private struct PlotColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .dark
}

extension EnvironmentValues {
    /// `preferredColorScheme` と同期した Plotty のライト/ダーク。ガラス内の誤判定回避用。
    var plotColorScheme: ColorScheme {
        get { self[PlotColorSchemeKey.self] }
        set { self[PlotColorSchemeKey.self] = newValue }
    }
}

/// テーマトークンを `ColorScheme` から取得（`Color.white` / `.primary` は使わない）。
enum PlotColors {
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .darkTextPrimary : .lightTextPrimary
    }
    
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .darkTextSecondary : .lightTextSecondary
    }
    
    static func textUser(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .darkTextUser : .lightTextUser
    }
    
    static func textAI(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .darkTextAI : .lightTextAI
    }
    
    static func selectedBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.28) : Color.black.opacity(0.14)
    }
}
