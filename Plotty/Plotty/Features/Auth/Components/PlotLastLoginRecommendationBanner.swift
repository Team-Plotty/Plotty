import SwiftUI

// MARK: - 前回ログイン方式の推奨（D4 / Apple Relay 対策）
struct PlotLastLoginRecommendationBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    let provider: AuthProvider

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: provider.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("おすすめ")
                    .font(.scaledCaption().weight(.semibold))
                    .foregroundStyle(Color.accentColor)

                Text(provider.loginRecommendationMessage)
                    .font(.scaledBodySmall())
                    .foregroundStyle(primaryColor)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(provider.loginRecommendationMessage)
    }

    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}

// MARK: - 推奨バッジ（ボタン上）
struct PlotRecommendedProviderBadge: View {
    var body: some View {
        Text("前回の方法")
            .font(.scaledMicro().weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            }
    }
}

extension AuthProvider {
    /// 前回ログイン方式の推奨メッセージ。
    var loginRecommendationMessage: String {
        switch self {
        case .google:
            return "前回は Google でログインしました。同じ方法でのログインをおすすめします。"
        case .apple:
            return "前回は Apple でログインしました。同じ方法でのログインをおすすめします。"
        case .email:
            return "前回はメールでログインしました。同じ方法でのログインをおすすめします。"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PlotLastLoginRecommendationBanner(provider: .google)
        PlotLastLoginRecommendationBanner(provider: .apple)
    }
    .padding()
    .ambientBackground()
    .preferredColorScheme(.dark)
}
