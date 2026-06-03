import SwiftUI

// MARK: - 選択日の予定一覧
struct CalendarDayEventsSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let selectedDate: Date
    let events: [CalendarEvent]
    let onGoToToday: () -> Void
    let onSelectEvent: (CalendarEvent) -> Void
    let onEditEvent: (CalendarEvent) -> Void
    let onDeleteEvent: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Text(PlotDateFormatter.dateWithHoliday(selectedDate, language: appSettings.language))
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                Spacer()
                
                PlotHIGBorderedButton("今日へ", systemImage: "calendar") {
                    onGoToToday()
                }
                .accessibilityLabel("今日の日付へ移動")
            }
            
            Text("予定 \(events.count)件")
                .font(.scaledCaption())
                .foregroundStyle(tertiaryTextColor)
            
            if events.isEmpty {
                CalendarEmptyEventsState()
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(events) { event in
                        PlotCardActionRow(
                            onEdit: { onEditEvent(event) },
                            onDelete: { onDeleteEvent(event.id) }
                        ) {
                            Button {
                                onSelectEvent(event)
                            } label: {
                                EventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}

// MARK: - 予定なし
struct CalendarEmptyEventsState: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
            
            Text("予定はありません")
                .font(.scaledBodyMedium())
                .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
