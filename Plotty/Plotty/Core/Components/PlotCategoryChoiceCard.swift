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
            VStack(spacing: Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor)
                    .frame(height: 26)
                
                Text(category.label)
                    .font(.scaledCaption())
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                if isSelected {
                    Label("選択中", systemImage: "checkmark.circle.fill")
                        .font(.scaledCaption().weight(.bold))
                        .foregroundStyle(accentColor)
                        .labelStyle(.iconOnly)
                        .accessibilityHidden(true)
                } else {
                    Color.clear
                        .frame(height: 14)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.minTouchTarget + 20)
            .background { cardFace }
            .overlay { selectionOverlay }
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
