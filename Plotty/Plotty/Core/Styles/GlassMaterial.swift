import SwiftUI

// MARK: - ガラス風レイヤーの濃さ（用途別プリセット）
enum GlassType {
    case heavy    /// ユーザー吹き出しなど、一番しっかりしたガラス
    case medium   /// AI 吹き出し・通常カード
    case light    /// 内側の小さな要素
    case input    /// 入力バー専用
    
    // ダークモード: 白を載せて明るく
    var fillOpacityDark: Double {
        switch self {
        case .heavy: return 0.12
        case .medium: return 0.06
        case .light: return 0.03
        case .input: return 0.08
        }
    }
    
    // ライトモード: 白ガラス（65% / 30%）でフローティング
    var fillOpacityLight: Double {
        switch self {
        case .heavy: return 0.65
        case .medium: return 0.50
        case .light: return 0.30
        case .input: return 0.55
        }
    }
    
    var shadowOpacity: Double {
        switch self {
        case .heavy: return 0.12
        case .medium: return 0.08
        case .light: return 0.05
        case .input: return 0.15
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .heavy: return 16
        case .medium: return 12
        case .light: return 6
        case .input: return 20
        }
    }
}

// MARK: - ガラス調の塗り（形はジェネリックで差し替え可能）
struct PremiumGlass<S: Shape>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let shape: S
    var glassType: GlassType = .medium
    
    var body: some View {
        if colorScheme == .dark {
            darkGlass
        } else {
            lightGlass
        }
    }
    
    // MARK: - ダークモード用のガラス
    private var darkGlass: some View {
        ZStack {
            /// 奥にぼかしマテリアル
            shape
                .fill(.ultraThinMaterial)
            
            /// 手前に白を薄く載せてコントラストを出す
            shape
                .fill(Color.white.opacity(glassType.fillOpacityDark))
            
            /// 上から下へのハイライト（立体感）
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .blendMode(.plusLighter)
                .opacity(0.5)
            
            /// 縁の細いグラデーション線
            shape
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: Color.black.opacity(glassType.shadowOpacity),
            radius: glassType.shadowRadius,
            x: 0,
            y: glassType.shadowRadius * 0.3
        )
    }
    
    // MARK: - ライトモード用の白いすりガラス
    private var lightGlass: some View {
        ZStack {
            /// 白ベースのすりガラス（不透明度は `GlassType` で切り替え）
            shape
                .fill(Color.white.opacity(glassType.fillOpacityLight))
            
            /// 上側を少し明るく見せる縦グラデーション
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(glassType.fillOpacityLight * 0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            /// 輪郭をほんのり区切る白線
            shape
                .stroke(
                    Color.white.opacity(0.8),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: Color.black.opacity(glassType.shadowOpacity * 0.6),
            radius: glassType.shadowRadius,
            x: 0,
            y: glassType.shadowRadius * 0.25
        )
    }
}

// MARK: - `.glassCard` 修飾子（中身の背後にガラス形を敷く）
struct GlassCard: ViewModifier {
    var glassType: GlassType = .medium
    var radius: CGFloat = Radius.lg
    
    func body(content: Content) -> some View {
        content
            .background(
                PremiumGlass(
                    shape: RoundedRectangle(cornerRadius: radius, style: .continuous),
                    glassType: glassType
                )
            )
    }
}

// MARK: - 不透明度指定版のガラスカード（既存コードとの互換用）
struct GlassCardCustom: ViewModifier {
    var opacity: Double = 0.07
    var borderOpacity: Double = 0.11
    var radius: CGFloat = Radius.lg
    
    func body(content: Content) -> some View {
        content
            .background(
                PremiumGlass(
                    shape: RoundedRectangle(cornerRadius: radius, style: .continuous),
                    glassType: opacity >= 0.12 ? .heavy : (opacity >= 0.06 ? .medium : .light)
                )
            )
    }
}

// MARK: - View へのショートカット（`glassHeavy` など）
extension View {
    func glassCard(_ type: GlassType = .medium, radius: CGFloat = Radius.lg) -> some View {
        modifier(GlassCard(glassType: type, radius: radius))
    }
    
    func glassCard(opacity: Double = 0.07, borderOpacity: Double = 0.11, radius: CGFloat = Radius.lg) -> some View {
        modifier(GlassCardCustom(opacity: opacity, borderOpacity: borderOpacity, radius: radius))
    }
    
    func glassHeavy(radius: CGFloat = Radius.lg) -> some View {
        glassCard(.heavy, radius: radius)
    }
    
    func glassMedium(radius: CGFloat = Radius.lg) -> some View {
        glassCard(.medium, radius: radius)
    }
    
    func glassLight(radius: CGFloat = Radius.lg) -> some View {
        glassCard(.light, radius: radius)
    }
    
    func glassInput(radius: CGFloat = Radius.pill) -> some View {
        glassCard(.input, radius: radius)
    }
    
    /// 検索・メッセージ入力などカプセル型フィールド用（テーマの入力背景・枠線。文字が潰れないよう `glassEffect` は使わない）。
    func plotInputCapsuleGlass() -> some View {
        modifier(PlotInputCapsuleGlass())
    }
    
    /// チャット入力欄（固定角丸。チップ追加時は縦に伸ばす。`Capsule` は高さ可変で形が崩れるため使わない）。
    func plotChatComposerGlass(cornerRadius: CGFloat = PlotChatComposerMetrics.cornerRadius) -> some View {
        modifier(PlotChatComposerGlass(cornerRadius: cornerRadius))
    }
    
    /// カプセル型チップの Liquid Glass（チャット吹き出し内など。フィルタは `PlotFilterChip` を使う）。
    func plotChipGlassCapsule(style: PlotChipGlassStyle = .standalone) -> some View {
        background {
            Capsule(style: .continuous)
                .fill(Color.clear)
                .glassEffect(style.glass, in: .capsule)
        }
    }
    
    /// 一覧カード（メモ・TODO・カレンダー予定で共通。`EventRow` と同じ Liquid Glass）。
    func plotListCardGlass(cornerRadius: CGFloat = Radius.md) -> some View {
        glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - チップ用 Liquid Glass（Apple HIG の functional layer）
enum PlotChipGlassStyle {
    /// フィルタ・カテゴリなど単独のチップ
    case standalone
    /// 吹き出しなど既に Liquid Glass な面の上に載せるチップ
    case nestedInGlass
    
    /// 押下・ホバーは `ButtonStyle` 側で行い、ガラスは屈折のみに任せる（`.interactive()` はラベル全体に効いて不自然になりやすい）。
    var glass: Glass {
        switch self {
        case .standalone:
            return .regular
        case .nestedInGlass:
            return .clear
        }
    }
}

// MARK: - チップの押下フィードバック（システム `.glass` に近い軽いスケール＋不透明度）
struct PlotChipPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if reduceMotion {
            configuration.label
                .opacity(configuration.isPressed ? 0.92 : 1)
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
        }
    }
}

// MARK: - チャット入力欄の寸法
enum PlotChatComposerMetrics {
    /// 1 行時と同じ角丸（高さが増えても角の曲率は固定）
    static let cornerRadius: CGFloat = 24
    static let minHeightCompact: CGFloat = 48
    static let minHeightWithChip: CGFloat = 84
}

// MARK: - チャット入力欄の背景（固定角丸の角丸矩形）
private struct PlotChatComposerGlass: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content.background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(colorScheme == .dark ? Color.darkInputBG : Color.lightInputBG)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? Color.darkBorderDefault : Color.lightBorderDefault,
                            lineWidth: 0.5
                        )
                )
        }
    }
}

// MARK: - カプセル型入力の背景（検索・チャット入力で共通）
/// `glassEffect` は `TextField` の文字・アイコンが潰れやすいため、テーマの入力用ベタ塗り＋枠線を使う。
private struct PlotInputCapsuleGlass: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content.background {
            Capsule(style: .continuous)
                .fill(colorScheme == .dark ? Color.darkInputBG : Color.lightInputBG)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? Color.darkBorderDefault : Color.lightBorderDefault,
                            lineWidth: 0.5
                        )
                )
        }
    }
}

// MARK: - チャット吹き出し専用のガラス背景（角だけユーザーと AI で違う）
struct UserBubbleBackground: View {
    var body: some View {
        PremiumGlass(
            shape: UnevenRoundedRectangle(
                topLeadingRadius: BubbleCorners.user.topLeading,
                bottomLeadingRadius: BubbleCorners.user.bottomLeading,
                bottomTrailingRadius: BubbleCorners.user.bottomTrailing,
                topTrailingRadius: BubbleCorners.user.topTrailing,
                style: .continuous
            ),
            glassType: .heavy
        )
    }
}

struct AIBubbleBackground: View {
    var body: some View {
        PremiumGlass(
            shape: UnevenRoundedRectangle(
                topLeadingRadius: BubbleCorners.ai.topLeading,
                bottomLeadingRadius: BubbleCorners.ai.bottomLeading,
                bottomTrailingRadius: BubbleCorners.ai.bottomTrailing,
                topTrailingRadius: BubbleCorners.ai.topTrailing,
                style: .continuous
            ),
            glassType: .medium
        )
    }
}
