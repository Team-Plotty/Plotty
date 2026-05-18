import SwiftUI

// MARK: - 入力欄内の登録先チップ（参考: Safari の Search チップ）
struct ChatCategoryInputChip: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    let category: PlotChatCategory
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: category.icon)
                .font(.system(size: 12, weight: .semibold))
            
            Text(category.quickActionTitle)
                .font(.scaledCaption().weight(.medium))
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("登録先を解除")
        }
        .foregroundStyle(foregroundColor)
        .padding(.leading, Spacing.sm)
        .padding(.trailing, Spacing.xxs)
        .padding(.vertical, 6)
        .background {
            Capsule(style: .continuous)
                .fill(backgroundColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("登録先、\(category.quickActionTitle)")
    }
    
    private var foregroundColor: Color {
        plotColorScheme == .dark
            ? category.chipTintDark
            : category.chipTintLight
    }
    
    private var backgroundColor: Color {
        foregroundColor.opacity(plotColorScheme == .dark ? 0.22 : 0.14)
    }
}
