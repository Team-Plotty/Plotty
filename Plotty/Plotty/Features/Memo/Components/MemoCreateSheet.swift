import SwiftUI

// MARK: - 新規メモ作成シート
struct MemoCreateSheet: View {
    @Binding var isPresented: Bool
    @Binding var draftTitle: String
    @Binding var draftContent: String
    @Binding var draftAccent: AccentSwatch
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タイトル", text: $draftTitle)
                    TextField("本文（任意）", text: $draftContent, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("内容")
                }
                
                Section {
                    Picker("カラー", selection: $draftAccent) {
                        ForEach(AccentSwatch.allCases) { swatch in
                            Label {
                                Text(swatch.title)
                            } icon: {
                                Circle()
                                    .fill(swatch.color)
                                    .frame(width: 12, height: 12)
                            }
                            .tag(swatch)
                        }
                    }
                }
            }
            .navigationTitle("新しいメモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarPrimarySheetActionButton("保存", action: onSave)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
