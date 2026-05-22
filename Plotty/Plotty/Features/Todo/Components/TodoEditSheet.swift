import SwiftUI

// MARK: - タスク編集シート
struct TodoEditSheet: View {
    @State private var draft: TodoItem
    let onSave: (TodoItem) -> Void
    let onCancel: () -> Void
    
    init(todo: TodoItem, onSave: @escaping (TodoItem) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: todo)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タスク名", text: $draft.title)
                    Toggle("完了", isOn: $draft.isCompleted)
                }
                Section {
                    Picker("優先度", selection: $draft.priority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    DatePicker("期限", selection: Binding(
                        get: { draft.dueDate ?? Date() },
                        set: { draft.dueDate = $0 }
                    ), displayedComponents: [.date])
                }
            }
            .navigationTitle("タスクを編集")
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
