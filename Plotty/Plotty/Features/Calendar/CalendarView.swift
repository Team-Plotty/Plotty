import SwiftUI

// MARK: - スケジュール（カレンダー）タブの画面
struct CalendarTabView: View {
    @Environment(\.plotDataStore) private var dataStore
    @Environment(\.connectivity) private var connectivity
    @Environment(\.plotTabHorizontalPaging) private var plotTabHorizontalPaging
    
    @Binding var showCreateSheet: Bool
    @Binding var pendingEntityRoute: PlotEntityRoute?
    
    @State private var monthAnchor = Date()
    @State private var selectedDate = Date()
    @State private var editingEvent: CalendarEvent?
    
    @State private var draftTitle = ""
    @State private var draftStart = Date()
    @State private var draftEnd = Date().addingTimeInterval(3600)
    @State private var draftSwatch: AccentSwatch = .sky
    @State private var draftLocation = ""
    @State private var draftNotes = ""
    @State private var draftIsAllDay = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    CalendarMonthNavigation(
                        monthAnchor: monthAnchor,
                        onPrevious: { shiftMonth(-1) },
                        onNext: { shiftMonth(1) }
                    )
                    
                    CalendarMonthGrid(
                        monthAnchor: monthAnchor,
                        selectedDate: selectedDate,
                        events: dataStore.events,
                        onSelectDate: selectDate
                    )
                }
                .padding(.top, Spacing.sm)
                
                CalendarDayEventsSection(
                    selectedDate: selectedDate,
                    events: eventsForSelectedDate,
                    onGoToToday: goToToday,
                    onEditEvent: { editingEvent = $0 },
                    onDeleteEvent: removeEvent
                )
                .padding(.top, Spacing.lg)
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.tabbedScrollBottomInset)
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(plotTabHorizontalPaging)
        .plotListLoading(dataStore.isLoading(.events))
        .task { await reloadEvents() }
        .refreshable { await reloadEvents() }
        .onChange(of: connectivity.isOnline) { _, _ in
            if connectivity.isOnline { Task { await reloadEvents() } }
        }
        .sheet(isPresented: $showCreateSheet) {
            CalendarCreateSheet(
                isPresented: $showCreateSheet,
                draftTitle: $draftTitle,
                draftStart: $draftStart,
                draftEnd: $draftEnd,
                draftSwatch: $draftSwatch,
                draftLocation: $draftLocation,
                draftNotes: $draftNotes,
                draftIsAllDay: $draftIsAllDay,
                onSave: saveEvent
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationSizing(.page)
        }
        .onChange(of: showCreateSheet) { _, isShowing in
            if isShowing {
                prepareCreateDraft()
            }
        }
        .sheet(item: $editingEvent) { event in
            EventEditSheet(event: event) { updated in
                Task {
                    let ok = await dataStore.updateEvent(updated, isOnline: connectivity.isOnline)
                    if ok { editingEvent = nil }
                }
            } onCancel: {
                editingEvent = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationSizing(.page)
            .plotErrorAlert("保存できませんでした", message: dataStore.errorMessageBinding(for: .events))
        }
        // 編集シートを開いている間は出さない（シートの裏からはアラートを出せないため。編集時はシート側で出す）
        .plotErrorAlert(
            "同期できませんでした",
            message: editingEvent == nil ? dataStore.errorMessageBinding(for: .events) : .constant(nil),
            onRetry: { Task { await reloadEvents() } }
        )
        .plotOpensEntityRoute(
            $pendingEntityRoute,
            category: .schedule,
            find: { id in dataStore.events.first { $0.id == id } },
            reload: reloadEvents,
            open: openEvent
        )
    }
    
    /// 編集を閉じたあとも、その予定の日がカレンダーで選ばれた状態にしておく
    private func openEvent(_ event: CalendarEvent) {
        selectedDate = event.startTime
        monthAnchor = event.startTime
        editingEvent = event
    }
    
    private func saveEvent() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        var start = draftStart
        var end = draftEnd
        if draftIsAllDay {
            (start, end) = CalendarEvent.allDayRange(on: draftStart, calendar: calendar)
        }
        let ev = CalendarEvent(
            title: title,
            startTime: start,
            endTime: end,
            swatch: draftSwatch,
            location: draftLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: draftNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            isAllDay: draftIsAllDay
        )
        withAnimation(.standard) {
            dataStore.addEvent(ev)
        }
        showCreateSheet = false
    }
    
    private func removeEvent(id: UUID) {
        Task {
            _ = await dataStore.deleteEvent(id: id, isOnline: connectivity.isOnline)
        }
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        dataStore.events
            .filter { calendar.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
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
    
    private func reloadEvents() async {
        await dataStore.reload(.events, isOnline: connectivity.isOnline)
    }
    
    private func shiftMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            withAnimation(.quick) {
                monthAnchor = d
            }
        }
    }
    
    /// 新規作成シート用の初期値を準備
    /// - 選択中の日付 + 現在の時刻を開始時刻にする
    private func prepareCreateDraft() {
        let now = Date()
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let selectedDayStart = calendar.startOfDay(for: selectedDate)
        
        // 選択中の日付に現在時刻を合成
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDayStart)
        startComponents.hour = nowComponents.hour
        startComponents.minute = nowComponents.minute
        
        let start = calendar.date(from: startComponents) ?? selectedDayStart
        let end = start.addingTimeInterval(3600) // 1時間後
        
        draftTitle = ""
        draftStart = start
        draftEnd = end
        draftSwatch = .sky
        draftLocation = ""
        draftNotes = ""
        draftIsAllDay = false
    }
}

#Preview {
    CalendarTabView(showCreateSheet: .constant(false), pendingEntityRoute: .constant(nil))
        .environment(\.plotDataStore, PlotDataStore.previewSample())
        .ambientBackground()
        .preferredColorScheme(.dark)
}
