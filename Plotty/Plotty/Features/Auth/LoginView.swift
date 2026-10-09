import AuthenticationServices
import SwiftUI
import Supabase

// MARK: - 認証フローの経路
/// ログイン画面の上にクロスディゾルブで重ねる画面。
private enum AuthRoute: Hashable {
    case signUp
    /// 入力済みのメールアドレスを引き継いで開く。
    case passwordRecovery(email: String)
    case emailOTP(EmailOTPChallenge)
}

// MARK: - ログイン画面
struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity

    @State private var email = ""
    @State private var password = ""
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showRelayHelp = false
    @State private var showRelayGuidance = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var path: [AuthRoute] = []
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    private var recommendedProvider: AuthProvider? {
        accountSession.lastUsedProvider
    }

    var body: some View {
        PlotCrossDissolveStack(path: $path) {
            loginContent
        } destination: { route in
            switch route {
            case .signUp:
                SignUpView()
            case .passwordRecovery(let email):
                PasswordRecoveryView(initialEmail: email) { challenge in
                    path.append(.emailOTP(challenge))
                }
            case .emailOTP(let challenge):
                EmailOTPVerificationView(challenge: challenge) {
                    path.removeAll()
                }
            }
        }
    }

    private var loginContent: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    PlotAuthHeader(subtitle: "チャットから予定・タスク・メモを整理")
                        .padding(.top, Spacing.xxl)

                    if !connectivity.isOnline {
                        PlotOfflineBanner()
                    }

                    if let recommendedProvider {
                        PlotLastLoginRecommendationBanner(provider: recommendedProvider)
                    }

                    if showRelayGuidance || recommendedProvider == .apple {
                        relayHelpCard
                    }

                    if let errorMessage {
                        PlotErrorBanner(message: errorMessage, onRetry: nil)
                    }

                    authMethodSections

                    PlotAuthSwitchLink(prompt: "アカウントをお持ちでない方", actionTitle: "新規登録") {
                        path.append(.signUp)
                    }

                    legalLinks
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
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                LegalDocumentView(kind: .termsOfService)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationSizing(.page)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                LegalDocumentView(kind: .privacyPolicy)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationSizing(.page)
        }
        .sheet(isPresented: $showRelayHelp) {
            NavigationStack {
                HelpView(highlightRelay: true)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationSizing(.page)
        }
        .overlay {
            if isLoading {
                PlotLoadingOverlay(message: "ログインしています…")
            }
        }
        .plotAnalyticsScreen(.login)
    }

    @ViewBuilder
    private var authMethodSections: some View {
        if recommendedProvider == .google || recommendedProvider == .apple {
            snsLoginButtons
            PlotAuthDivider()
            emailLoginForm
        } else {
            emailLoginForm
            PlotAuthDivider()
            snsLoginButtons
        }
    }

    private var emailLoginForm: some View {
        let isRecommended = recommendedProvider == .email

        return VStack(spacing: Spacing.md) {
            HStack {
                Text("メールアドレス")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                Spacer(minLength: 0)
                if isRecommended {
                    PlotRecommendedProviderBadge()
                }
            }

            TextField("example@email.com", text: $email)
                .font(.scaledBodyLarge())
                .foregroundStyle(primaryColor)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .plotAuthInputField(isHighlighted: isRecommended)
                // ラベルと入力欄の組の境目を分かりやすくする
                .padding(.bottom, Spacing.xs)

            fieldLabel("パスワード")

            PlotAuthPasswordField(text: $password, isHighlighted: isRecommended)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit(loginWithPassword)

            Button("パスワードをお忘れの方") {
                path.append(.passwordRecovery(email: email.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
            .font(.scaledBodySmall().weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .trailing)

            Button("ログイン", action: loginWithPassword)
                .disabled(!canLoginWithPassword || isLoading)
                .buttonStyle(PlotAuthPrimaryButtonStyle(isEnabled: canLoginWithPassword && !isLoading, isRecommended: isRecommended))
                .padding(.top, Spacing.sm)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.scaledCaption())
            .foregroundStyle(secondaryColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var snsLoginButtons: some View {
        VStack(spacing: Spacing.sm) {
            if recommendedProvider == .apple {
                appleSignInButton
                googleSignInButton
            } else {
                googleSignInButton
                appleSignInButton
            }
        }
    }

    private var googleSignInButton: some View {
        let isRecommended = recommendedProvider == .google

        return VStack(spacing: Spacing.xs) {
            if isRecommended {
                HStack {
                    Spacer(minLength: 0)
                    PlotRecommendedProviderBadge()
                }
            }

            Button {
                login(with: .google)
            } label: {
                PlotSocialSignInLabel(title: "Googleでログイン", icon: Image(.googleLogo))
            }
            .buttonStyle(PlotSocialSignInButtonStyle(isRecommended: isRecommended))
            .disabled(isLoading || !connectivity.isOnline)
        }
    }

    private var appleSignInButton: some View {
        let isRecommended = recommendedProvider == .apple

        return VStack(spacing: Spacing.xs) {
            if isRecommended {
                HStack {
                    Spacer(minLength: 0)
                    PlotRecommendedProviderBadge()
                }
            }

            PlotAppleSignInButton(
                purpose: .signIn,
                isDisabled: isLoading || !connectivity.isOnline,
                isRecommended: isRecommended
            ) { result in
                handleAppleSignIn(result)
            }
        }
    }

    private var legalLinks: some View {
        HStack(spacing: Spacing.lg) {
            Button("利用規約") { showTerms = true }
            Button("プライバシー") { showPrivacy = true }
        }
        .font(.scaledCaption())
        .foregroundStyle(secondaryColor)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.lg)
    }

    private var relayHelpCard: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Apple の非公開メールでお困りですか？")
                    .font(.scaledBodySmall().weight(.semibold))
                    .foregroundStyle(primaryColor)

                Text("「Hide My Email」で別アカウント扱いになることがあります。解決手順をヘルプで確認できます。")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)

                Button("解決手順を見る") {
                    showRelayHelp = true
                }
                .font(.scaledCaption().weight(.semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    private var canLoginWithPassword: Bool {
        isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) && !password.isEmpty
    }

    private func loginWithPassword() {
        guard canLoginWithPassword else { return }
        focusedField = nil
        errorMessage = nil
        showRelayGuidance = false
        isLoading = true

        Task {
            let result = await accountSession.signInWithPassword(
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

    private func login(with provider: AuthProvider) {
        errorMessage = nil
        showRelayGuidance = false
        isLoading = true
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            let result = await accountSession.performLogin(
                provider: provider,
                email: mail.isEmpty ? nil : mail,
                isOnline: connectivity.isOnline
            )
            await MainActor.run {
                isLoading = false
                switch result {
                case .success:
                    break
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<AppleSignInPayload, Error>) {
        errorMessage = nil
        isLoading = true
        Task {
            let authResult: Result<Void, AuthError>
            switch result {
            case .success(let payload):
                authResult = accountSession.completeSupabaseSignIn(
                    payload.session,
                    displayNameOverride: payload.suggestedDisplayName
                )
            case .failure:
                authResult = .failure(.appleRelayHint)
            }
            await MainActor.run {
                isLoading = false
                if case .failure(let error) = authResult {
                    errorMessage = error.localizedDescription
                    if error == .appleRelayHint {
                        showRelayGuidance = true
                    }
                }
            }
        }
    }

    // MARK: - Colors

    private var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryColor: Color {
        PlotAuthPalette.secondary(colorScheme)
    }
}

#if DEBUG
#Preview("Google 推奨") {
    LoginView()
        .environment(\.accountSession, AccountSession.preview(loggedIn: false, lastProvider: .google))
        .environment(\.connectivity, ConnectivityMonitor())
}

#Preview("メール推奨") {
    LoginView()
        .environment(\.accountSession, AccountSession.preview(loggedIn: false, lastProvider: .email))
        .environment(\.connectivity, ConnectivityMonitor())
}
#endif
