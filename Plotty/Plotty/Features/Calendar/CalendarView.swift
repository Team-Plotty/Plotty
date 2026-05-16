import SwiftUI

// MARK: - スケジュール（カレンダー）タブの画面
struct CalendarTabView: View {
    @Environment(\.plotDataStore) private var dataStore
    
    @Binding var showCreateSheet: Bool
    
    @State private var monthAnchor = Date()
    @State private var selectedDate = Date()
    @State private var selectedEvent: CalendarEvent?
    @State private var editingEvent: CalendarEvent?
    
    @State private var draftTitle = ""
    @State private var draftStart = Date()
    @State private var draftEnd = Date().addingTimeInterval(3600)
    @State private var draftSwatch: AccentSwatch = .sky
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
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
                
                CalendarDayEventsSection(
                    selectedDate: selectedDate,
                    events: eventsForSelectedDate,
                    onGoToToday: goToToday,
                    onSelectEvent: { selectedEvent = $0 },
                    onDeleteEvent: removeEvent
                )
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.tabbedScrollBottomInset)
        }
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showCreateSheet) {
            CalendarCreateSheet(
                isPresented: $showCreateSheet,
                draftTitle: $draftTitle,
                draftStart: $draftStart,
                draftEnd: $draftEnd,
                draftSwatch: $draftSwatch,
                onSave: saveEvent
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(
                event: event,
                onClose: { selectedEvent = nil },
                onEdit: {
                    editingEvent = event
                    selectedEvent = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingEvent) { event in
            EventEditSheet(event: event) { updated in
                dataStore.updateEvent(updated)
                editingEvent = nil
            } onCancel: {
                editingEvent = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func saveEvent() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let ev = CalendarEvent(
            title: title,
            startTime: draftStart,
            endTime: draftEnd,
            swatch: draftSwatch,
            location: "",
            notes: "",
            isAllDay: false
        )
        withAnimation(.standard) {
            dataStore.addEvent(ev)
        }
        showCreateSheet = false
    }
    
    private func removeEvent(id: UUID) {
        withAnimation(.standard) {
            dataStore.deleteEvent(id: id)
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
    
    private func shiftMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            withAnimation(.quick) {
                monthAnchor = d
            }
        }
    }
}

#Preview {
    CalendarTabView(showCreateSheet: .constant(false))
        .environment(\.plotDataStore, PlotDataStore())
        .ambientBackground()
        .preferredColorScheme(.dark)
}
