import SwiftUI

// MARK: - 月間カレンダーグリッド
struct CalendarMonthGrid: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let monthAnchor: Date
    let selectedDate: Date
    let events: [CalendarEvent]
    let onSelectDate: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.scaledCaption())
                        .foregroundStyle(tertiaryTextColor)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, cell in
                    if let date = cell {
                        dayCell(date)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(Spacing.sm)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
    }
    
    private var weekdaySymbols: [String] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        return df.shortWeekdaySymbols ?? ["日", "月", "火", "水", "木", "金", "土"]
    }
    
    private var monthCells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let first = interval.start
        let daysInMonth = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: first)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...daysInMonth {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: first) {
                cells.append(d)
            }
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }
    
    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayEvents = events.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
        
        return Button {
            onSelectDate(date)
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.scaledBodyMedium())
                    .foregroundStyle(isSelected ? textColor : secondaryTextColor)
                HStack(spacing: 2) {
                    ForEach(0..<min(dayEvents.count, 3), id: \.self) { i in
                        Circle()
                            .fill(dayEvents[i].color)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
                if isToday {
                    Capsule()
                        .fill(Color.accentColor.opacity(0.9))
                        .frame(width: 14, height: 2)
                } else {
                    Spacer().frame(height: 2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(isSelected
                          ? (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                          : Color.clear)
            )
        }
        .buttonStyle(.plain)
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
