import SwiftUI

// MARK: - 共通 UI 状態（loading / error / offline）
enum PlotAsyncPhase: Equatable {
    case idle
    case loading
    case error(String)
}

// エラー・オフラインの表示はアラートに統一（`PlotErrorAlert.swift`）
struct PlotLoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .controlSize(.large)
                Text(message)
                    .font(.scaledBodyMedium())
                    .foregroundStyle(.primary)
            }
            .padding(Spacing.xl)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - AI 応答待ちの画面枠（背景は暗くしない・枠のみ）
struct PlotAIScreenBorder: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var rotation: Double = 0
    
    private let edgeInset: CGFloat = 1.5
    private let lineWidth: CGFloat = 3.5
    
    var body: some View {
        GeometryReader { geometry in
            let cornerRadius = PlotDeviceDisplayMetrics.displayCornerRadius(for: geometry.size)
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            
            shape
                .strokeBorder(borderGradient, lineWidth: lineWidth)
                .shadow(color: Color.plotAIBorderGlow.opacity(0.9), radius: 10)
                .shadow(color: Color.plotAIBorderGlow.opacity(0.45), radius: 22)
                .frame(
                    width: max(0, geometry.size.width - edgeInset * 2),
                    height: max(0, geometry.size.height - edgeInset * 2)
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityLabel("AI が応答を作成中")
        .onAppear(perform: startAnimation)
    }
    
    private var borderGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: PlotBorderChaserPalette.aiGlow.gradientStops(colorScheme: colorScheme)),
            center: .center,
            startAngle: .degrees(rotation),
            endAngle: .degrees(rotation + 360)
        )
    }
    
    private func startAnimation() {
        guard !reduceMotion else { return }
        rotation = 0
        withAnimation(.linear(duration: BorderChaserSpeed.normal.duration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}
