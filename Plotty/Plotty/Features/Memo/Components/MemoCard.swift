import SwiftUI

// MARK: - メモを一枚のカードとして表示（カレンダー `EventRow` と同じカード面）
struct MemoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let memo: MemoItem
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(memo.accent.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Text(memo.title)
                        .font(.scaledBodyLarge())
                        .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                        .lineLimit(1)
                    
                    if memo.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(memo.accent.color)
                            .accessibilityLabel("ピン留め済み")
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.trailing, Spacing.minTouchTarget - Spacing.xs)
                .animation(.standard, value: memo.isPinned)
                
                if !memo.content.isEmpty {
                    Text(memo.content)
                        .font(.scaledCaption())
                        .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
                        .lineLimit(2)
                }
                
                Text(PlotDateFormatter.dateTime(memo.updatedAt, language: appSettings.language))
                    .font(.scaledCaption())
                    .foregroundStyle(colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
    }
}
