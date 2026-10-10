import SwiftUI

// MARK: - カテゴリ選択カード（一覧カードと同じ Liquid Glass・選択状態を明確に）
struct PlotCategoryChoiceCard: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let category: PlotChatCategory
    let isSelected: Bool
    let action: () -> Void
    
    private let cornerRadius = Radius.md
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor)
                    .frame(height: 22)
                
                Text(category.label)
                    .font(.scaledCaption())
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.minTouchTarget)
            .background { cardFace }
            .overlay { selectionOverlay }
            // 専用の行を取ると選択の有無でカード全体が縦に伸びるため、角に重ねて高さを使わない
            .overlay(alignment: .topTrailing) { selectedBadge }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(PlotChipPressButtonStyle())
        .disabled(isSelected)
        .accessibilityLabel(category.label)
        .accessibilityHint(isSelected ? "現在の登録先" : "タップして登録先を変更")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
    }
    
    @ViewBuilder
    private var cardFace: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tintFill)
            .plotListCardGlass(cornerRadius: cornerRadius)
    }
    
    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(accentColor, lineWidth: 2.5)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(PlotColors.selectedBorder(plotColorScheme).opacity(0.35), lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private var selectedBadge: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accentColor)
                .padding(Spacing.xxs + 2)
                .accessibilityHidden(true)
        }
    }
    
    private var accentColor: Color {
        plotColorScheme == .dark ? category.chipTintDark : category.chipTintLight
    }
    
    private var tintFill: Color {
        if isSelected {
            return accentColor.opacity(plotColorScheme == .dark ? 0.32 : 0.18)
        }
        return Color.clear
    }
    
    private var iconColor: Color {
        isSelected ? accentColor : PlotColors.textSecondary(plotColorScheme)
    }
    
    private var labelColor: Color {
        isSelected ? PlotColors.textPrimary(plotColorScheme) : PlotColors.textSecondary(plotColorScheme)
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        PlotCategoryChoiceCard(category: .schedule, isSelected: false, action: {})
        PlotCategoryChoiceCard(category: .task, isSelected: true, action: {})
        PlotCategoryChoiceCard(category: .memo, isSelected: false, action: {})
    }
    .padding()
    .ambientBackground()
    .environment(\.plotColorScheme, .dark)
}
