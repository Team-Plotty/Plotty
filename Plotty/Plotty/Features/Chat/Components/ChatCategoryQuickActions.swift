import SwiftUI

// MARK: - キーボード表示時の登録先クイックアクション（横一列）
struct ChatCategoryQuickActions: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    let onSelect: (PlotChatCategory) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PlotChatCategory.quickActionOrder) { category in
                Button {
                    onSelect(category)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(iconColor)
                        
                        Text(category.quickActionTitle)
                            .font(.scaledBodyMedium())
                            .foregroundStyle(textColor)
                            // 3等分の幅に収めるため、大きい文字サイズでは折り返さず縮める
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: Spacing.minTouchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.detail)
            }
        }
        .padding(.horizontal, Spacing.xxs)
        .plotChatComposerSurface()
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
