import SwiftUI

// MARK: - パスワード設定（メールアカウント向け）
/// 認証コードでログインした後のパスワード再設定と、OTP 時代に作られたパスワード未設定アカウントの初回設定を兼ねる。
struct PasswordSettingsSheet: View {
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var saveError: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 入力欄自体がガラス背景なので、カードで二重に囲まずラベル＋入力欄だけにする
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("新しいパスワード")
                            .font(.scaledCaption())
                            .foregroundStyle(.secondary)
                        PlotAuthPasswordField(text: $password, isNewPassword: true)
                            .submitLabel(.done)
                            .onSubmit(save)
                    }

                    Text("\(PlotInputLimits.passwordMinimum)文字以上で入力してください。次回からメールアドレスとこのパスワードでログインできます。")
                        .font(.scaledCaption())
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.lg)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("パスワードを設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(isSaving || !canSave)
                }
            }
            .overlay {
                if isSaving {
                    PlotLoadingOverlay(message: "保存しています…")
                }
            }
            .plotErrorAlert("保存できませんでした", message: $saveError)
        }
        .plotAnalyticsScreen(.passwordSettings)
        .frame(maxWidth: .infinity)
    }

    private var canSave: Bool {
        password.count >= PlotInputLimits.passwordMinimum
    }

    private func save() {
        guard canSave, !isSaving else { return }
        saveError = nil
        isSaving = true

        Task { @MainActor in
            let result = await accountSession.updatePassword(password, isOnline: connectivity.isOnline)
            isSaving = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                saveError = error.localizedDescription
            }
        }
    }
}

#if DEBUG
#Preview {
    PasswordSettingsSheet()
        .environment(\.accountSession, AccountSession.preview())
        .environment(\.connectivity, ConnectivityMonitor())
}
#endif
