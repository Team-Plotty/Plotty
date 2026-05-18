import SwiftUI

// MARK: - 予定を一行で表示
struct EventRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(event.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                    .lineLimit(1)
                
                Text("\(event.startTime.formatted(date: .omitted, time: .shortened)) - \(event.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.scaledCaption())
                    .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .padding(.trailing, Spacing.minTouchTarget - Spacing.xs)
    }
}
