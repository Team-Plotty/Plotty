import SwiftUI

// MARK: - 新規タスク作成シート
struct TodoCreateSheet: View {
    @Binding var isPresented: Bool
    @Binding var draftTitle: String
    @Binding var draftPriority: TodoItem.Priority
    let onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タスク名", text: $draftTitle)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("内容")
                }
                
                Section {
                    Picker("優先度", selection: $draftPriority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("優先度")
                } footer: {
                    Text("高い優先度のタスクが一覧の上に表示されやすくなります。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarPrimarySheetActionButton("追加", action: onAdd)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
