import SwiftUI

// MARK: - パスワードを忘れたときの入口
/// パスワードの再設定メールは使わず、認証コードでいったんログインしてもらい、
/// ログイン後に設定画面で新しいパスワードを登録してもらう（OTP 時代に作られたパスワード未設定のアカウントもこの経路で救う）。
struct PasswordRecoveryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity

    /// 認証コードを送信できたとき、コード入力画面への遷移を親に依頼する。
    let onCodeSent: (EmailOTPChallenge) -> Void

    @State private var email: String
    @State private var errorMessage: String?
    @State private var isLoading = false
    @FocusState private var isEmailFocused: Bool

    init(initialEmail: String = "", onCodeSent: @escaping (EmailOTPChallenge) -> Void) {
        _email = State(initialValue: initialEmail)
        self.onCodeSent = onCodeSent
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header

                    emailForm
                }
                .padding(.horizontal, Spacing.screenEdge)
                // 左上に重なる戻るボタン（44pt）の下から見出しを始める
                .padding(.top, Spacing.minTouchTarget + Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isEmailFocused = false
        }
        .navigationTitle("パスワードをお忘れの方")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading {
                PlotLoadingOverlay(message: "送信しています…")
            }
        }
        .plotErrorAlert("送信できませんでした", message: $errorMessage)
        .plotAnalyticsScreen(.passwordRecovery)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("認証コードでログイン")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)

            Text("登録済みのメールアドレスに認証コードをお送りします。ログイン後、設定画面の「パスワードを設定」から新しいパスワードを登録してください。")
                .font(.scaledBodyMedium())
                .foregroundStyle(PlotAuthPalette.secondary(colorScheme))
        }
    }

    private var emailForm: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("メールアドレス")
                .font(.scaledCaption())
                .foregroundStyle(PlotAuthPalette.secondary(colorScheme))

            TextField("メールアドレス", text: $email, prompt: PlotAuthPlaceholder.email)
                .font(.scaledBodyLarge())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .focused($isEmailFocused)
                .submitLabel(.send)
                .onSubmit(sendCode)
                .plotAuthInputField()

            Button("認証コードを送信", action: sendCode)
                .disabled(!canSend || isLoading)
                .buttonStyle(PlotAuthPrimaryButtonStyle(isEnabled: canSend && !isLoading))
                .padding(.top, Spacing.sm)
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        trimmedEmail.range(of: #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }

    private func sendCode() {
        guard canSend else { return }
        isEmailFocused = false
        errorMessage = nil
        isLoading = true
        let mail = trimmedEmail

        Task {
            let result = await accountSession.sendEmailOTP(email: mail, isOnline: connectivity.isOnline)
            await MainActor.run {
                isLoading = false
                switch result {
                case .success:
                    onCodeSent(EmailOTPChallenge(email: mail))
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PasswordRecoveryView(initialEmail: "preview@plotty.app") { _ in }
            .environment(\.accountSession, AccountSession.preview(loggedIn: false))
            .environment(\.connectivity, ConnectivityMonitor())
    }
}
#endif
