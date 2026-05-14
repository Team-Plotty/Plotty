import SwiftUI

// MARK: - 予定（カレンダー用のデータモデル）
struct CalendarEvent: Identifiable {
    let id = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var swatch: AccentSwatch
    
    var color: Color { swatch.color }
}

// MARK: - スケジュール（カレンダー）タブの画面
struct CalendarTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// 親のタブ（カレンダー以外に切り替えたら検索のフォーカスを外す）
    var selectedTab: TabItem = .calendar
    @Binding var showCreateSheet: Bool
    
    @State private var monthAnchor = Date()
    @State private var selectedDate = Date()
    @State private var events: [CalendarEvent] = CalendarEvent.sampleData
    
    @State private var searchText = ""
    @State private var draftTitle = ""
    @State private var draftStart = Date()
    @State private var draftEnd = Date().addingTimeInterval(3600)
    @State private var draftSwatch: AccentSwatch = .sky
    
    @FocusState private var isSearchFocused: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                PlotTopSearchRow(
                    text: $searchText,
                    isFocused: $isSearchFocused
                )
                
                monthNavigation
                
                monthGrid
                
                todayEvents
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.floatingAddButtonClearance)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                isSearchFocused = false
            }
        )
        .onChange(of: selectedTab) { _, newTab in
            if newTab != .calendar {
                isSearchFocused = false
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var monthNavigation: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .buttonStyle(GlassIconButtonStyle())
            
            Spacer()
            
            Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                .font(.scaledTitleSmall())
                .foregroundStyle(textColor)
            
            Spacer()
            
            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .buttonStyle(GlassIconButtonStyle())
        }
    }
    
    private var monthGrid: some View {
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
        let count = dayEvents.count
        
        return Button {
            selectDate(date)
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.scaledBodyMedium())
                    .foregroundStyle(isSelected ? textColor : secondaryTextColor)
                HStack(spacing: 2) {
                    ForEach(0..<min(count, 3), id: \.self) { i in
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
    
    private var todayEvents: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                Spacer()
                
                Button("今日へ") { goToToday() }
                    .font(.scaledCaption())
                    .foregroundStyle(textColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
            
            Text("予定 \(todayEventCount)件")
                .font(.scaledCaption())
                .foregroundStyle(tertiaryTextColor)
            
            if todayEventCount == 0 {
                emptyEventsState
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(filteredEventsForDay) { event in
                        EventRow(event: event)
                    }
                }
            }
        }
    }
    
    private var filteredEventsForDay: [CalendarEvent] {
        let day = eventsForSelectedDate
        guard !searchText.isEmpty else { return day }
        return day.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var createSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TextField("タイトル", text: $draftTitle)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                DatePicker("開始", selection: $draftStart, displayedComponents: [.date, .hourAndMinute])
                DatePicker("終了", selection: $draftEnd, displayedComponents: [.date, .hourAndMinute])
                
                Text("カラー")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(AccentSwatch.allCases) { sw in
                        Button {
                            draftSwatch = sw
                        } label: {
                            Circle()
                                .fill(sw.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .strokeBorder(draftSwatch == sw ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .navigationTitle("予定を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { showCreateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarPrimarySheetActionButton("保存", action: saveEvent)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func openCreateSheet() {
        draftTitle = ""
        draftStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        draftEnd = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: selectedDate) ?? selectedDate.addingTimeInterval(3600)
        draftSwatch = .sky
        showCreateSheet = true
    }
    
    private func saveEvent() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let ev = CalendarEvent(title: title, startTime: draftStart, endTime: draftEnd, swatch: draftSwatch)
        withAnimation(.standard) {
            events.append(ev)
        }
        showCreateSheet = false
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
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
            monthAnchor = Date()
        }
    }
    
    private func shiftMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            withAnimation(.quick) {
                monthAnchor = d
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

// MARK: - 予定を一行で表示する行
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

// MARK: - プレビュー用のダミーデータ
extension CalendarEvent {
    static var sampleData: [CalendarEvent] {
        let today = Date()
        let cal = Calendar.current
        let y = cal.date(byAdding: .day, value: -1, to: today)!
        
        return [
            CalendarEvent(
                title: "チームミーティング",
                startTime: cal.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
                swatch: .sky
            ),
            CalendarEvent(
                title: "ランチ",
                startTime: cal.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
                endTime: cal.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
                swatch: .sage
            ),
            CalendarEvent(
                title: "昨日の振り返り",
                startTime: cal.date(bySettingHour: 18, minute: 0, second: 0, of: y)!,
                endTime: cal.date(bySettingHour: 18, minute: 45, second: 0, of: y)!,
                swatch: .coral
            ),
        ]
    }
}

#Preview {
    CalendarTabView(showCreateSheet: .constant(false))
        .ambientBackground()
        .preferredColorScheme(.dark)
}
