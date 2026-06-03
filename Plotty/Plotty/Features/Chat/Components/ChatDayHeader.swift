import SwiftUI

// MARK: - チャットの日付見出し
struct ChatDayHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let day: Date
    
    var body: some View {
        Text(PlotDateFormatter.date(day, language: appSettings.language))
            .font(.scaledCaption())
            .foregroundStyle(colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
    }
}
