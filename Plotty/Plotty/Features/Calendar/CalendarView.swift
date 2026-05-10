import SwiftUI

// MARK: - Calendar Event Model
struct CalendarEvent: Identifiable {
    let id = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var color: Color
}

// MARK: - Calendar View
struct CalendarTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedDate = Date()
    @State private var events: [CalendarEvent] = CalendarEvent.sampleData
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                
                weekStrip
                
                todayEvents
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.xl)
            .padding(.bottom, 140)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.scaledDisplayMedium())
                    .titleTracking()
                    .foregroundStyle(textColor)
                
                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.scaledBodyMedium())
                    .foregroundStyle(secondaryTextColor)
            }
            
            Spacer()
            
            Button(action: goToToday) {
                Text("今日")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(textColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
            }
            .glassCard(.light, radius: Radius.pill)
        }
    }
    
    // MARK: - Week Strip
    private var weekStrip: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(weekDays, id: \.self) { date in
                dayCell(date)
            }
        }
    }
    
    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        
        return Button(action: { selectDate(date) }) {
            VStack(spacing: Spacing.xxs) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.scaledCaption())
                    .foregroundStyle(isSelected ? textColor : tertiaryTextColor)
                
                Text(date.formatted(.dateTime.day()))
                    .font(.scaledTitleSmall())
                    .foregroundStyle(isSelected ? textColor : secondaryTextColor)
                
                if isToday && !isSelected {
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.4))
                        .frame(width: 4, height: 4)
                } else {
                    Spacer().frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(isSelected
                          ? (colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.08))
                          : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Today Events
    private var todayEvents: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("予定")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                Spacer()
                
                Text("\(todayEventCount)件")
                    .font(.scaledCaption())
                    .foregroundStyle(tertiaryTextColor)
            }
            
            if todayEventCount == 0 {
                emptyEventsState
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(eventsForSelectedDate) { event in
                        EventRow(event: event)
                    }
                }
            }
        }
    }
    
    private var emptyEventsState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(secondaryTextColor)
            
            Text("予定はありません")
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .glassCard(.light, radius: Radius.md)
    }
    
    // MARK: - Helpers
    private var weekDays: [Date] {
        let today = Date()
        return (-3...3).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        events.filter { calendar.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private var todayEventCount: Int {
        eventsForSelectedDate.count
    }
    
    private func selectDate(_ date: Date) {
        withAnimation(.quick) {
            selectedDate = date
        }
    }
    
    private func goToToday() {
        withAnimation(.standard) {
            selectedDate = Date()
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

// MARK: - Event Row
private struct EventRow: View {
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
            
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .glassCard(.medium, radius: Radius.md)
    }
}

// MARK: - Sample Data
extension CalendarEvent {
    static var sampleData: [CalendarEvent] {
        let today = Date()
        let calendar = Calendar.current
        
        return [
            CalendarEvent(
                title: "チームミーティング",
                startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
                color: .white.opacity(0.9)
            ),
            CalendarEvent(
                title: "ランチ",
                startTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
                color: .white.opacity(0.6)
            ),
            CalendarEvent(
                title: "デザインレビュー",
                startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today)!,
                color: .white.opacity(0.9)
            ),
        ]
    }
}

#Preview {
    CalendarTabView()
        .ambientBackground()
        .preferredColorScheme(.dark)
}
