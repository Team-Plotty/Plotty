import SwiftUI

// MARK: - 予定詳細シート
struct EventDetailSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let event: CalendarEvent
    let onClose: () -> Void
    let onEdit: () -> Void
    
    private var allDayText: String {
        appSettings.language == .japanese ? "終日" : "All day"
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(event.title)
                    .font(.scaledTitleSmall())
                    .foregroundStyle(textColor)
                
                if event.isAllDay {
                    Text(allDayText)
                        .font(.scaledBodyMedium())
                        .foregroundStyle(secondaryTextColor)
                } else {
                    Text(PlotDateFormatter.dateTimeRange(from: event.startTime, to: event.endTime, language: appSettings.language))
                        .font(.scaledBodyMedium())
                        .foregroundStyle(secondaryTextColor)
                }
                
                if !event.location.isEmpty {
                    Label(event.location, systemImage: "mappin")
                        .font(.scaledBodySmall())
                        .foregroundStyle(secondaryTextColor)
                }
                
                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(.scaledBodySmall())
                        .foregroundStyle(tertiaryTextColor)
                }
                
                Spacer(minLength: 0)
                
                Button("編集", action: onEdit)
                    .filledButtonStyle()
            }
            .padding(Spacing.lg)
            .navigationTitle("予定の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onClose)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}
