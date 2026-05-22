import SwiftUI

// MARK: - 予定詳細シート
struct EventDetailSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    let event: CalendarEvent
    let onClose: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(event.title)
                    .font(.scaledTitleSmall())
                    .foregroundStyle(textColor)
                
                if event.isAllDay {
                    Text("終日")
                        .font(.scaledBodyMedium())
                        .foregroundStyle(secondaryTextColor)
                } else {
                    Text("\(event.startTime.formatted(date: .abbreviated, time: .shortened)) 〜 \(event.endTime.formatted(date: .abbreviated, time: .shortened))")
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
