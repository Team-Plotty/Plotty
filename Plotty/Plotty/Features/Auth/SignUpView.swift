// [SNS認証停止] 認証はメールのみで運用するため Google / Apple は無効化中
// import AuthenticationServices
import SwiftUI
import Supabase

// MARK: - 新規登録画面
/// メールアドレスとパスワードだけで登録を完了する。表示名は登録後に設定画面から任意で登録してもらう。
struct SignUpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity
    @Environment(\.plotCrossDissolveDismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var agreedToTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    PlotAuthHeader(subtitle: "アカウントを作成してはじめましょう")
                        .padding(.top, Spacing.xxl)
                    
                    if !connectivity.isOnline {
                        PlotOfflineBanner()
                    }
                    
                    if let errorMessage {
                        PlotErrorBanner(message: errorMessage, onRetry: nil)
                    }
                    
                    emailSignUpForm
                    
                    // [SNS認証停止]
                    // PlotAuthDivider()
                    //
                    // snsSignUpButtons
                    
                    PlotAuthSwitchLink(prompt: "すでにアカウントをお持ちの方", actionTitle: "ログイン") {
                        dismiss()
                    }
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTerms) {
            NavigationStack { LegalDocumentView(kind: .termsOfService) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationSizing(.page)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack { LegalDocumentView(kind: .privacyPolicy) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationSizing(.page)
        }
        .overlay {
            if isLoading {
                PlotLoadingOverlay(message: "登録しています…")
            }
        }
        .plotAnalyticsScreen(.signUp)
    }
    
    /// ログイン画面のメールフォームと同じ並び（ラベル → 入力欄 → 補足 → ボタン）に揃えている。
    private var emailSignUpForm: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            fieldLabel("メールアドレス")
            
            TextField("メールアドレス", text: $email, prompt: PlotAuthPlaceholder.email)
                .font(.scaledBodyLarge())
                .foregroundStyle(primaryColor)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .plotAuthInputField()
                // ラベルと入力欄の組の境目を分かりやすくする
                .padding(.bottom, Spacing.xs)

            fieldLabel("パスワード")

            PlotAuthPasswordField(text: $password, isNewPassword: true)
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit(signUpWithPassword)

            Text("\(PlotInputLimits.passwordMinimum)文字以上で入力してください。表示名はあとから設定画面で登録できます。")
                .font(.scaledCaption())
                .foregroundStyle(secondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            PlotTermsConsentRow(
                isAgreed: $agreedToTerms,
                onShowTerms: { showTerms = true },
                onShowPrivacy: { showPrivacy = true }
            )
            
            Button("登録する", action: signUpWithPassword)
                .disabled(!canSubmit || isLoading)
                .buttonStyle(PlotAuthPrimaryButtonStyle(isEnabled: canSubmit && !isLoading))
                .padding(.top, Spacing.sm)
        }
    }
    
    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.scaledCaption())
            .foregroundStyle(secondaryColor)
    }
    
    // [SNS認証停止] Google / Apple の登録ボタン
    // private var snsSignUpButtons: some View {
    //     VStack(spacing: Spacing.sm) {
    //         // Google
    //         Button {
    //             signUp(with: .google)
    //         } label: {
    //             PlotSocialSignInLabel(title: "Googleで登録", icon: Image(.googleLogo))
    //         }
    //         .buttonStyle(PlotSocialSignInButtonStyle())
    //         .disabled(isLoading || !connectivity.isOnline || !agreedToTerms)
    //
    //         // Apple
    //         PlotAppleSignInButton(
    //             purpose: .signUp,
    //             isDisabled: isLoading || !connectivity.isOnline || !agreedToTerms
    //         ) { result in
    //             handleAppleSignUp(result)
    //         }
    //
    //         if !agreedToTerms {
    //             Text("SNSで登録するには利用規約への同意が必要です")
    //                 .font(.scaledCaption())
    //                 .foregroundStyle(secondaryColor)
    //                 .frame(maxWidth: .infinity)
    //         }
    //     }
    // }
    
    private var canSubmit: Bool {
        agreedToTerms &&
        isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) &&
        password.count >= PlotInputLimits.passwordMinimum
    }

    private func signUpWithPassword() {
        guard canSubmit else {
            if !agreedToTerms {
                errorMessage = "利用規約に同意してください。"
            }
            return
        }
        focusedField = nil
        errorMessage = nil
        isLoading = true

        Task {
            let result = await accountSession.signUpWithPassword(
                email: email,
                password: password,
                isOnline: connectivity.isOnline
            )
            await MainActor.run {
                isLoading = false
                if case .failure(let error) = result {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func isValidEmail(_ raw: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return raw.range(of: pattern, options: .regularExpression) != nil
    }

    // [SNS認証停止] Google / Apple の登録処理
    // private func signUp(with provider: AuthProvider) {
    //     guard agreedToTerms else {
    //         errorMessage = "利用規約に同意してください。"
    //         return
    //     }
    //
    //     errorMessage = nil
    //     isLoading = true
    //
    //     Task {
    //         let result = await accountSession.performSignUp(
    //             email: email.trimmingCharacters(in: .whitespacesAndNewlines),
    //             provider: provider,
    //             isOnline: connectivity.isOnline
    //         )
    //         await MainActor.run {
    //             isLoading = false
    //             switch result {
    //             case .success:
    //                 dismiss()
    //             case .failure(let error):
    //                 errorMessage = error.localizedDescription
    //             }
    //         }
    //     }
    // }
    //
    // private func handleAppleSignUp(_ result: Result<AppleSignInPayload, Error>) {
    //     guard agreedToTerms else {
    //         errorMessage = "利用規約に同意してください。"
    //         return
    //     }
    //
    //     errorMessage = nil
    //     isLoading = true
    //
    //     Task {
    //         let authResult: Result<Void, AuthError>
    //         switch result {
    //         case .success(let payload):
    //             authResult = accountSession.completeSupabaseSignIn(
    //                 payload.session,
    //                 displayNameOverride: payload.suggestedDisplayName,
    //                 isSignUp: true
    //             )
    //         case .failure:
    //             authResult = .failure(.providerUnavailable(AuthProvider.apple.title))
    //         }
    //         await MainActor.run {
    //             isLoading = false
    //             switch authResult {
    //             case .success:
    //                 dismiss()
    //             case .failure(let error):
    //                 errorMessage = error.localizedDescription
    //             }
    //         }
    //     }
    // }
    
    // MARK: - Colors
    
    private var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var secondaryColor: Color {
        PlotAuthPalette.secondary(colorScheme)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SignUpView()
            .environment(\.accountSession, AccountSession.preview())
            .environment(\.connectivity, ConnectivityMonitor())
    }
}
#endif
