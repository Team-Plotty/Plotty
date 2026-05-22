import SwiftUI

struct ChatView: View {
    @State private var isComposerPresented = false
    @State private var draftTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("チャット")
                .font(.title2.bold())
            Text("右上の吹き出しから作成パネルを開けます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .navigationTitle("Plotty")
        .navigationBarTitleDisplayMode(.inline)
        .plottySideSlideEditor(isPresented: $isComposerPresented, bubbleTitle: "作成") {
            NavigationStack {
                Form {
                    Section("メッセージ") {
                        TextField("タイトルやメモ", text: $draftTitle, axis: .vertical)
                            .lineLimit(3 ... 8)
                    }
                }
                .navigationTitle("新規作成")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                isComposerPresented = false
                            }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            // TODO: API へ送信
                            draftTitle = ""
                            withAnimation(.easeInOut(duration: 0.28)) {
                                isComposerPresented = false
                            }
                        }
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}
