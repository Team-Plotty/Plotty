import SwiftUI

// MARK: - ボタンの高さと余白（タップしやすさの段階）
enum ButtonSize {
    case xl    /// 高さ 56pt・画面で一番目立たせる操作
    case lg    /// 高さ 50pt・セクションの主ボタン
    case md    /// 高さ 44pt・Apple HIG の最小タップ領域（標準）
    case sm    /// 高さ 36pt・補助的な操作
    case xs    /// 高さ 28pt・チップやインラインのみ向け
    
    var height: CGFloat {
        switch self {
        case .xl: return 56
        case .lg: return 50
        case .md: return 44
        case .sm: return 36
        case .xs: return 28
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .xl: return 28
        case .lg: return 24
        case .md: return 20
        case .sm: return 16
        case .xs: return 12
        }
    }
    
    var font: Font {
        switch self {
        case .xl, .lg, .md: return .system(size: 17, weight: .semibold)
        case .sm: return .system(size: 13, weight: .medium)
        case .xs: return .system(size: 12, weight: .medium)
        }
    }
}

// MARK: - ボタンの見た目の種類（塗り / 枠線 / 危険操作など）
enum ButtonStyleType {
    case filled      /// メイン操作（塗りつぶし）
    case tinted      /// キャンセルや副次的な操作
    case glass       /// 重なった面の上に置く半透明
    case outline     /// 代替の枠線だけの操作
    case destructive /// 削除など危険な操作（赤の例外を許容）
    case plain       /// 「スキップ」など装飾の少ないテキスト
}

// MARK: - 塗りつぶしボタン（`FilledButtonStyle`）
struct FilledButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkBase : .lightBase)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isEnabled
                          ? (colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                          : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)))
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - 薄い背景のボタン（`TintedButtonStyle`）
struct TintedButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.10)
                          : Color.black.opacity(0.06))
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - ガラス調のボタン（`GlassButtonStyle`）
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.07)
                                  : Color.black.opacity(0.045))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(colorScheme == .dark
                                          ? Color.white.opacity(0.14)
                                          : Color.black.opacity(0.10), lineWidth: 0.5)
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - 枠線だけのボタン（`OutlineButtonStyle`）
struct OutlineButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(colorScheme == .dark
                                  ? Color.white.opacity(0.22)
                                  : Color.black.opacity(0.13), lineWidth: 1.5)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - 削除など危険操作向けボタン（`DestructiveButtonStyle`）
struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(Color.red.opacity(0.90))
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.08)
                          : Color.black.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.50), lineWidth: 1)
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - 装飾の少ないテキストボタン（`PlainTextButtonStyle`）
struct PlainTextButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var size: ButtonSize = .md
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - 円形アイコンボタン（塗りあり / なし）
struct CircleIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    enum Size {
        case lg  /// 52×52 pt
        case md  /// 44×44 pt
        case sm  /// 36×36 pt
        
        var dimension: CGFloat {
            switch self {
            case .lg: return 52
            case .md: return 44
            case .sm: return 36
            }
        }
    }
    
    var size: Size = .md
    var filled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size.dimension, height: size.dimension)
            .background(
                Circle()
                    .fill(filled
                          ? (colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                          : .clear)
            )
            .overlay(
                Circle()
                    .strokeBorder(colorScheme == .dark
                                  ? Color.white.opacity(0.14)
                                  : Color.black.opacity(0.10), lineWidth: filled ? 0 : 0.5)
            )
            .foregroundColor(filled
                             ? (colorScheme == .dark ? .darkBase : .lightBase)
                             : (colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary))
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - ガラス風の円形アイコンボタン（検索横の「＋」など）
struct GlassIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var dimension: CGFloat = 44
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: dimension, height: dimension)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.07)
                                  : Color.black.opacity(0.045))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(colorScheme == .dark
                                          ? Color.white.opacity(0.14)
                                          : Color.black.opacity(0.10), lineWidth: 0.5)
                    )
            )
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
            .opacity(isEnabled ? 1.0 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.quick, value: configuration.isPressed)
    }
}

// MARK: - シート上部ツールバー用の主ボタン（保存・追加など）
/// Apple の [ボタン HIG](https://developer.apple.com/design/human-interface-guidelines/buttons) に近づけた見た目。
/// 有効時はアクセント色、無効時は二次色。最小 44×44pt。押したときは不透明度だけ変えてレイアウトは動かさない。
struct ToolbarPrimarySheetActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(foregroundColor)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(pressedOpacity(isPressed: configuration.isPressed))
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.18), value: isEnabled)
    }
    
    private var foregroundColor: Color {
        isEnabled ? Color.accentColor : Color.secondary
    }
    
    private func pressedOpacity(isPressed: Bool) -> Double {
        guard isEnabled, isPressed else { return 1.0 }
        return 0.88
    }
}

// MARK: - 一覧カードと同じ Liquid Glass の補助ボタン（44pt・青塗りなし）
// https://developer.apple.com/design/human-interface-guidelines/buttons

/// 単発アクション・フィルタ向け（例: 「すべて」「今日へ」）。
struct PlotHIGBorderedButton: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    let title: String
    var systemImage: String? = nil
    var isSelected: Bool = false
    let action: () -> Void
    
    init(
        _ title: String,
        systemImage: String? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            label
                .font(.scaledCaption().weight(isSelected ? .semibold : .medium))
                .foregroundStyle(labelColor)
                .symbolRenderingMode(.monochrome)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .frame(minHeight: Spacing.minTouchTarget)
                .plotChipGlassCapsule()
                .overlay {
                    if isSelected {
                        Capsule(style: .continuous)
                            .strokeBorder(selectedBorderColor, lineWidth: 1)
                    }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PlotChipPressButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    @ViewBuilder
    private var label: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
        } else {
            Text(title)
        }
    }
    
    private var labelColor: Color {
        if isSelected {
            return PlotColors.textPrimary(plotColorScheme)
        }
        return PlotColors.textSecondary(plotColorScheme)
    }
    
    private var selectedBorderColor: Color {
        PlotColors.selectedBorder(plotColorScheme)
    }
}

/// ナビゲーションバー右側の確定ボタン向け（「保存」「追加」など）。
struct ToolbarPrimarySheetActionButton: View {
    let title: String
    let action: () -> Void
    
    /// 先頭のラベルを省略して `ToolbarPrimarySheetActionButton("保存", action: { … })` と書ける初期化子。
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(ToolbarPrimarySheetActionButtonStyle())
    }
}

// MARK: - 各種 `ButtonStyle` を一行で適用するショートカット
extension View {
    func filledButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(FilledButtonStyle(size: size))
    }
    
    func tintedButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(TintedButtonStyle(size: size))
    }
    
    func glassButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(GlassButtonStyle(size: size))
    }
    
    func outlineButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(OutlineButtonStyle(size: size))
    }
    
    func destructiveButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(DestructiveButtonStyle(size: size))
    }
    
    func plainTextButtonStyle(size: ButtonSize = .md) -> some View {
        buttonStyle(PlainTextButtonStyle(size: size))
    }
}
