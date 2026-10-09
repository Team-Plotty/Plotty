import SwiftUI

/// SNS ログインボタン共通のラベル（ロゴ左寄せ・タイトル中央）。
/// Google / Apple でロゴ幅が違ってもタイトル位置がずれないよう、ロゴはタイトルと重ねて左端に固定する。
struct PlotSocialSignInLabel: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    /// ブランドロゴ。Google の多色ロゴは着色されないよう、アセット側で original 描画にしている。
    let icon: Image

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        ZStack {
            Text(title)
                .font(.scaledBodyLarge().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, iconSize + Spacing.lg * 2)

            HStack {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
            }
            .padding(.leading, Spacing.lg)
        }
        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
}

/// SNS ログインボタン共通のアウトラインスタイル。
/// 各社のガイドライン（Google: 白／黒地＋公式ロゴ、Apple: 白枠線／黒地）を同時に満たす最小公倍数として、
/// 面は無彩色・細い枠線のみで統一する。
struct PlotSocialSignInButtonStyle: ButtonStyle {
    var isRecommended: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, isRecommended: isRecommended)
    }

    private struct StyledBody: View {
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.isEnabled) private var isEnabled

        let configuration: Configuration
        let isRecommended: Bool

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: Radius.md, style: .continuous)

            configuration.label
                .background(shape.fill(fillColor))
                .overlay(shape.strokeBorder(borderColor, lineWidth: 1))
                .contentShape(shape)
                .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1.0) : 0.5)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }

        private var fillColor: Color {
            colorScheme == .dark ? .black : .white
        }

        private var borderColor: Color {
            if isRecommended, isEnabled {
                return Color.accentColor.opacity(0.6)
            }
            return colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: Spacing.sm) {
        Button {} label: {
            PlotSocialSignInLabel(title: "Googleでログイン", icon: Image(.googleLogo))
        }
        .buttonStyle(PlotSocialSignInButtonStyle(isRecommended: true))

        Button {} label: {
            PlotSocialSignInLabel(title: "Appleでログイン", icon: Image(systemName: "apple.logo"))
        }
        .buttonStyle(PlotSocialSignInButtonStyle())
    }
    .padding()
}
#endif
