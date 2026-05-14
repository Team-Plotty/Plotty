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
