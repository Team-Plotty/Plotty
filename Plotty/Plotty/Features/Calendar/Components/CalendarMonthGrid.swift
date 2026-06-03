import SwiftUI

// MARK: - カレンダーのセル情報
private struct CalendarCellData: Identifiable {
    let id: Int
    let date: Date
    let isCurrentMonth: Bool
}

// MARK: - 月間カレンダーグリッド
struct CalendarMonthGrid: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let monthAnchor: Date
    let selectedDate: Date
    let events: [CalendarEvent]
    let onSelectDate: (Date) -> Void
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        
        VStack(spacing: Spacing.sm) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, sym in
                    Text(sym)
                        .font(.scaledCaption())
                        .foregroundStyle(weekdayHeaderColor(index: index))
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(monthCells) { cell in
                    dayCell(cell.date, isCurrentMonth: cell.isCurrentMonth)
                }
            }
        }
        .padding(Spacing.sm)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
    
    private func weekdayHeaderColor(index: Int) -> Color {
        if index == 0 { return Color.red.opacity(0.85) }
        if index == 6 { return Color.blue.opacity(0.85) }
        return tertiaryTextColor
    }
    
    /// グリッドは日曜始まり固定のため、曜日ラベルも日〜土の順に揃える
    private var weekdaySymbols: [String] {
        switch appSettings.language {
        case .japanese:
            return ["日", "月", "火", "水", "木", "金", "土"]
        case .english:
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }
    
    private var monthCells: [CalendarCellData] {
        let monthComponents = calendar.dateComponents([.year, .month], from: monthAnchor)
        guard let firstOfMonth = calendar.date(from: monthComponents),
              let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingOffset = (firstWeekday - calendar.firstWeekday + 7) % 7
        let totalDaySlots = leadingOffset + daysInMonth
        let trailingOffset = (7 - (totalDaySlots % 7)) % 7
        let totalCells = totalDaySlots + trailingOffset
        
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingOffset, to: firstOfMonth) else {
            return []
        }
        
        return (0..<totalCells).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let isCurrentMonth = calendar.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
            return CalendarCellData(id: offset, date: date, isCurrentMonth: isCurrentMonth)
        }
    }
    
    private func dayCell(_ date: Date, isCurrentMonth: Bool) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate) && isCurrentMonth
        let isToday = calendar.isDateInToday(date) && isCurrentMonth
        let dayEvents = isCurrentMonth ? events.filter { calendar.isDate($0.startTime, inSameDayAs: date) } : []
        let isSunday = calendar.component(.weekday, from: date) == 1
        let isSaturday = calendar.component(.weekday, from: date) == 7
        let isHoliday = isCurrentMonth && PlotJapaneseCalendar.isHoliday(date)
        
        return Button {
            if isCurrentMonth {
                onSelectDate(date)
            }
        } label: {
            VStack(spacing: 3) {
                // 日付数字
                Text("\(calendar.component(.day, from: date))")
                    .font(.scaledBodyMedium())
                    .foregroundStyle(dayTextColor(
                        isSelected: isSelected,
                        isSunday: isSunday,
                        isSaturday: isSaturday,
                        isHoliday: isHoliday,
                        isCurrentMonth: isCurrentMonth
                    ))
                
                // 予定ドット（最大3つ）
                HStack(spacing: 3) {
                    if dayEvents.isEmpty {
                        Color.clear.frame(width: 5, height: 5)
                    } else {
                        ForEach(Array(dayEvents.prefix(3).enumerated()), id: \.offset) { _, event in
                            Circle()
                                .fill(event.color)
                                .frame(width: 5, height: 5)
                        }
                    }
                }
                .frame(height: 5)
                
                // 今日インジケータ
                if isToday {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 16, height: 3)
                } else {
                    Color.clear.frame(height: 3)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isCurrentMonth)
    }
    
    private func dayTextColor(isSelected: Bool, isSunday: Bool, isSaturday: Bool, isHoliday: Bool, isCurrentMonth: Bool) -> Color {
        let opacity: Double = isCurrentMonth ? 1.0 : 0.3
        
        if isSunday || isHoliday {
            return Color.red.opacity((isSelected ? 1.0 : 0.85) * opacity)
        } else if isSaturday {
            return Color.blue.opacity((isSelected ? 1.0 : 0.85) * opacity)
        }
        
        if !isCurrentMonth {
            return tertiaryTextColor.opacity(0.5)
        }
        return isSelected ? textColor : secondaryTextColor
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
