import SwiftUI

// MARK: - 枠線が回る演出の速さ（1周にかかる秒数）
enum BorderChaserSpeed {
    case slow   /// 4.0 秒・目立たせたくない待機向け
    case normal /// 2.4 秒・通常の AI 処理中など
    case fast   /// 1.2 秒・送信直後など短い処理向け
    
    var duration: Double {
        switch self {
        case .slow: return 4.0
        case .normal: return 2.4
        case .fast: return 1.2
        }
    }
}

// MARK: - 角丸枠をなぞる光のグラデーション（回転アニメーション）
struct BorderChaserEffect: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var speed: BorderChaserSpeed = .normal
    var cornerRadius: CGFloat = Radius.pill
    var lineWidth: CGFloat = 1.5
    
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.95 : 0.80), location: 0.15),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.40 : 0.30), location: 0.35),
                            .init(color: .clear, location: 0.5)
                        ]),
                        center: .center,
                        startAngle: .degrees(rotation),
                        endAngle: .degrees(rotation + 360)
                    ),
                    lineWidth: lineWidth
                )
                .onAppear {
                    withAnimation(.linear(duration: speed.duration).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}

// MARK: - 枠が回る見た目のボタン（ラベルは呼び出し側で差し込む）
struct BorderChaserButton<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    var speed: BorderChaserSpeed = .normal
    var isAnimating: Bool = true
    var action: () -> Void
    @ViewBuilder var label: () -> Label
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            label()
                .frame(height: 44)
                .padding(.horizontal, Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.07)
                                      : Color.black.opacity(0.045))
                        )
                )
                .overlay(
                    Group {
                        if isAnimating && isEnabled {
                            BorderChaserEffect(speed: speed, cornerRadius: Radius.pill)
                        } else {
                            RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                                .strokeBorder(colorScheme == .dark
                                              ? Color.white.opacity(0.11)
                                              : Color.black.opacity(0.08), lineWidth: 0.5)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isPressed ? 0.6 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.quick) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.quick) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - 枠線チェイサーの色（送信ボタン / AI 枠で共用）
enum PlotBorderChaserPalette: Equatable {
    case subtle
    case aiGlow
    
    func gradientStops(colorScheme: ColorScheme) -> [Gradient.Stop] {
        switch self {
        case .subtle:
            return [
                .init(color: .clear, location: 0.0),
                .init(color: Color.white.opacity(colorScheme == .dark ? 0.95 : 0.80), location: 0.15),
                .init(color: Color.white.opacity(colorScheme == .dark ? 0.40 : 0.30), location: 0.35),
                .init(color: .clear, location: 0.5)
            ]
        case .aiGlow:
            return [
                .init(color: Color.plotAIBorderGlow.opacity(0.15), location: 0.0),
                .init(color: Color.plotAIBorderGlow.opacity(0.98), location: 0.14),
                .init(color: Color.cyan.opacity(0.85), location: 0.28),
                .init(color: Color.plotAIBorderGlow.opacity(0.12), location: 0.5),
                .init(color: Color.plotAIBorderGlow.opacity(0.95), location: 0.72),
                .init(color: Color.plotAIBorderGlow.opacity(0.2), location: 1.0)
            ]
        }
    }
}

// MARK: - 円形の枠線チェイサー（送信ボタンの border sweep）
struct CircleBorderChaser: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var speed: BorderChaserSpeed = .fast
    var palette: PlotBorderChaserPalette = .subtle
    var lineWidth: CGFloat = 2
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(stops: palette.gradientStops(colorScheme: colorScheme)),
                    center: .center,
                    startAngle: .degrees(rotation),
                    endAngle: .degrees(rotation + 360)
                ),
                lineWidth: lineWidth
            )
            .shadow(color: palette == .aiGlow ? Color.plotAIBorderGlow.opacity(0.55) : .clear, radius: 4)
            .onAppear(perform: startAnimation)
    }
    
    private func startAnimation() {
        guard !reduceMotion else { return }
        rotation = 0
        withAnimation(.linear(duration: speed.duration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}
