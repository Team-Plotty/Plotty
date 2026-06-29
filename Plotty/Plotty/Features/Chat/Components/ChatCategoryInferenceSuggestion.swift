import SwiftUI

// MARK: - 入力中のカテゴリ推論ヒント（タップで登録先チップを適用）
struct ChatCategoryInferenceSuggestion: View {
    @Environment(\.plotColorScheme) private var plotColorScheme

    let suggestion: PlotChatCategoryInference.Result
    let onApply: () -> Void

    var body: some View {
        Button(action: onApply) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)

                Image(systemName: suggestion.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)

                Text(suggestion.hint)
                    .font(.scaledCaption().weight(.semibold))
                    .foregroundStyle(primaryColor)

                Spacer(minLength: 0)

                Text("適用")
                    .font(.scaledCaption().weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .plotListCardGlass(cornerRadius: Radius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(suggestion.hint)。タップで登録先を適用")
    }

    private var primaryColor: Color {
        PlotColors.textPrimary(plotColorScheme)
    }

    private var accentColor: Color {
        plotColorScheme == .dark
            ? suggestion.category.chipTintDark
            : suggestion.category.chipTintLight
    }
}
