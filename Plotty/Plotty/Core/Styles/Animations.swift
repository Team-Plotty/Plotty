import SwiftUI

// MARK: - よく使うアニメーション（バネのきつさは HIG の体感に近づけた値）
extension Animation {
    static let standard = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let smooth = Animation.interactiveSpring(response: 0.35, dampingFraction: 0.7)
    static let page = Animation.easeInOut(duration: 0.3)
}

// MARK: - アニメーションの長さ（秒）
enum AnimationDuration {
    static let instant: Double = 0.1
    static let quick: Double = 0.2
    static let standard: Double = 0.3
    static let slow: Double = 0.5
    static let borderChaserSlow: Double = 4.0
    static let borderChaserNormal: Double = 2.4
    static let borderChaserFast: Double = 1.2
    static let doneReset: Double = 0.6
}

// MARK: - ボタン押下時の縮小・薄くする演出
struct PressEffect: ViewModifier {
    var isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.6 : 1.0)
            .animation(.quick, value: isPressed)
    }
}

extension View {
    func pressEffect(isPressed: Bool) -> some View {
        modifier(PressEffect(isPressed: isPressed))
    }
}

// MARK: - 表示時にふわっと出す演出
struct AppearAnimation: ViewModifier {
    @State private var isVisible = false
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                withAnimation(.standard.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearAnimation(delay: delay))
    }
}

// MARK: - 「動きを減らす」設定に合わせたアニメーション切り替え
struct ReducedMotionAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var animation: Animation
    var reducedAnimation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

extension View {
    func adaptiveAnimation(_ animation: Animation, reduced: Animation = .linear(duration: 0)) -> some View {
        modifier(ReducedMotionAnimation(animation: animation, reducedAnimation: reduced))
    }
}

// MARK: - 読み込み中などの脈打つ不透明度アニメーション
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.5 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}
