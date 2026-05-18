import SwiftUI

// MARK: - キーボード表示時の登録先クイックアクション（ChatGPT 風の縦リスト）
struct ChatCategoryQuickActions: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    let onSelect: (PlotChatCategory) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(PlotChatCategory.allCases) { category in
                Button {
                    onSelect(category)
                } label: {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: category.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(iconColor)
                            .frame(width: 28, alignment: .center)
                        
                        Text(category.quickActionTitle)
                            .font(.scaledBodyMedium())
                            .foregroundStyle(textColor)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, Spacing.xs)
                    .frame(minHeight: Spacing.minTouchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.detail)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .plotListCardGlass(cornerRadius: PlotChatComposerMetrics.cornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("登録先を選ぶ")
    }
    
    private var textColor: Color {
        PlotColors.textPrimary(plotColorScheme)
    }
    
    private var iconColor: Color {
        PlotColors.textSecondary(plotColorScheme)
    }
}
