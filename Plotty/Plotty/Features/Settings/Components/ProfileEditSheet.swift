import SwiftUI

// MARK: - 表示名編集（カード型フォーム）
struct ProfileEditSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var draftName: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    PlotFormCard(title: "表示名") {
                        TextField("表示名", text: $draftName)
                            .font(.scaledBodyLarge())
                            .foregroundStyle(textColor)
                            .onChange(of: draftName) { _, newValue in
                                draftName = PlotInputLimits.clamp(newValue, max: PlotInputLimits.displayName)
                            }
                        PlotCharacterCountFooter(
                            current: draftName.count,
                            maximum: PlotInputLimits.displayName
                        )
                    }
                    
                    Text("アイコンの変更は今後のアップデートで対応予定です。")
                        .font(.scaledCaption())
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.lg)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                draftName = accountSession.currentAccount?.displayName ?? ""
            }
        }
    }
    
    private func save() {
        accountSession.updateDisplayName(draftName)
        dismiss()
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
