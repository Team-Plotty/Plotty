import SwiftUI

// MARK: - メモを一枚のカードとして表示（カレンダー `EventRow` と同じカード面）
struct MemoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let memo: MemoItem
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(memo.accent.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(memo.title)
                        .font(.scaledBodyLarge())
                        .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if memo.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
                    }
                }
                
                if !memo.content.isEmpty {
                    Text(memo.content)
                        .font(.scaledCaption())
                        .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
                        .lineLimit(2)
                }
                
                Text(memo.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.scaledCaption())
                    .foregroundStyle(colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .plotListCardGlass()
    }
}
