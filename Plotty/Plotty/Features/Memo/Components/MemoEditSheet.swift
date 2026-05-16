import SwiftUI

// MARK: - メモ編集シート
struct MemoEditSheet: View {
    @State private var draft: MemoItem
    let onSave: (MemoItem) -> Void
    let onCancel: () -> Void
    
    init(memo: MemoItem, onSave: @escaping (MemoItem) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: memo)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タイトル", text: $draft.title)
                    TextField("本文", text: $draft.content, axis: .vertical)
                        .lineLimit(3...10)
                    Toggle("ピン留め", isOn: $draft.isPinned)
                }
            }
            .navigationTitle("メモを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        draft.updatedAt = Date()
                        onSave(draft)
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
