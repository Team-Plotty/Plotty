import SwiftUI

// MARK: - 予定編集シート
struct EventEditSheet: View {
    @State private var draft: CalendarEvent
    let onSave: (CalendarEvent) -> Void
    let onCancel: () -> Void
    
    init(event: CalendarEvent, onSave: @escaping (CalendarEvent) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: event)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("タイトル", text: $draft.title)
                    TextField("場所", text: $draft.location)
                    Toggle("終日", isOn: $draft.isAllDay)
                }
                Section("日時") {
                    EventTimeFields(start: $draft.startTime, end: $draft.endTime, isAllDay: draft.isAllDay)
                }
                Section("メモ") {
                    TextField("メモ", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle("予定を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { onSave(normalizedDraft) }
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var normalizedDraft: CalendarEvent {
        var saved = draft
        if saved.isAllDay {
            let range = CalendarEvent.allDayRange(on: saved.startTime)
            saved.startTime = range.start
            saved.endTime = range.end
        }
        return saved
    }
}
