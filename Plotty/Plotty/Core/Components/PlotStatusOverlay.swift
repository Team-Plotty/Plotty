import SwiftUI

// MARK: - 共通 UI 状態（loading / error / offline）
enum PlotAsyncPhase: Equatable {
    case idle
    case loading
    case error(String)
}

struct PlotOfflineBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))
            Text("オフラインです。送信にはインターネット接続が必要です。")
                .font(.scaledCaption())
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.22 : 0.15))
        )
        .accessibilityLabel("オフライン。送信にはインターネット接続が必要です。")
    }
}

struct PlotErrorBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: String
    var onRetry: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(message)
                    .font(.scaledCaption())
                    .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                    .multilineTextAlignment(.leading)
                
                if let onRetry {
                    Button("再試行", action: onRetry)
                        .font(.scaledCaption().weight(.semibold))
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.red.opacity(colorScheme == .dark ? 0.18 : 0.1))
        )
    }
}

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var rotation: Double = 0
    
    private let cornerRadius: CGFloat = 40
    private let edgeInset: CGFloat = 2
    private let lineWidth: CGFloat = 3.5
    
    var body: some View {
        GeometryReader { geometry in
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
            gradient: Gradient(stops: [
                .init(color: Color.plotAIBorderGlow.opacity(0.2), location: 0.0),
                .init(color: Color.plotAIBorderGlow.opacity(0.95), location: 0.14),
                .init(color: Color.cyan.opacity(0.75), location: 0.28),
                .init(color: Color.plotAIBorderGlow.opacity(0.15), location: 0.5),
                .init(color: Color.plotAIBorderGlow.opacity(0.92), location: 0.64),
                .init(color: Color.plotAIBorderGlow.opacity(0.25), location: 1.0)
            ]),
            center: .center,
            startAngle: .degrees(rotation),
            endAngle: .degrees(rotation + 360)
        )
    }
    
    private func startAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: BorderChaserSpeed.normal.duration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}
