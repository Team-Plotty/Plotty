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
                if !draft.isAllDay {
                    Section("日時") {
                        DatePicker("開始", selection: $draft.startTime)
                        DatePicker("終了", selection: $draft.endTime)
                    }
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
                    Button("保存") { onSave(draft) }
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
