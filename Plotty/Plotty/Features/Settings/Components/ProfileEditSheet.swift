import SwiftUI

// MARK: - 表示名編集（カード型フォーム）
struct ProfileEditSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.userSettingsSync) private var userSettingsSync
    @Environment(\.connectivity) private var connectivity
    @Environment(\.dismiss) private var dismiss
    
    @State private var draftName: String = ""
    @State private var saveError: String?
    @State private var isSaving = false
    
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
                    
                    if let saveError {
                        PlotErrorBanner(message: saveError, onRetry: nil)
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
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(
                            isSaving
                                || draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                }
            }
            .overlay {
                if isSaving {
                    PlotLoadingOverlay(message: "保存しています…")
                }
            }
            .onAppear {
                draftName = accountSession.currentAccount?.displayName ?? ""
                saveError = nil
            }
        }
        .plotAnalyticsScreen(.profileEdit)
        .frame(maxWidth: .infinity)
    }
    
    private func save() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        saveError = nil
        isSaving = true
        accountSession.updateDisplayName(trimmed)

        Task { @MainActor in
            let result = await userSettingsSync.pushDisplayName(trimmed, isOnline: connectivity.isOnline)
            isSaving = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                saveError = error.localizedDescription
            }
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
