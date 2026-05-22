import SwiftUI

// MARK: - チャットの日付見出し
struct ChatDayHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let day: Date
    
    var body: some View {
        Text(day.formatted(date: .long, time: .omitted))
            .font(.scaledCaption())
            .foregroundStyle(colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
    }
}
