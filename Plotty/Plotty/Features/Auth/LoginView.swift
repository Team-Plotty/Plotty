import AuthenticationServices
import SwiftUI
import Supabase

// MARK: - ログイン画面
struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity

    @State private var email = ""
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showRelayHelp = false
    @State private var showRelayGuidance = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var otpChallenge: EmailOTPChallenge?
    @FocusState private var isEmailFocused: Bool

    private var recommendedProvider: AuthProvider? {
        accountSession.lastUsedProvider
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        header
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

                        signUpLink

                        legalLinks
                    }
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, Spacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isEmailFocused = false
            }
            .navigationDestination(item: $otpChallenge) { challenge in
                EmailOTPVerificationView(challenge: challenge, onSuccess: {})
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
                    PlotLoadingOverlay(message: "送信しています…")
                }
            }
        }
    }

    @ViewBuilder
    private var authMethodSections: some View {
        if recommendedProvider == .google || recommendedProvider == .apple {
            snsLoginButtons
            divider
            emailLoginForm
        } else {
            emailLoginForm
            divider
            snsLoginButtons
        }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: Spacing.sm) {
            Text("Plotty")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(primaryColor)

            Text("チャットから予定・タスク・メモを整理")
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.lg)
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
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .focused($isEmailFocused)
                .submitLabel(.done)
                .onSubmit { sendEmailOTP() }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(minHeight: 50)
                .background {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Color.clear)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                }
                .overlay {
                    if isRecommended {
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                    }
                }

            Text("認証コードまたはログインリンクをメールでお送りします。")
                .font(.scaledCaption())
                .foregroundStyle(secondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: sendEmailOTP) {
                Text(EmailOTPPurpose.login.sendButtonTitle)
                    .font(.scaledBodyLarge().weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .disabled(!canSendEmailOTP || isLoading)
            .buttonStyle(LoginAccentButtonStyle(isEnabled: canSendEmailOTP && !isLoading, isRecommended: isRecommended))
            .padding(.top, Spacing.sm)
        }
    }

    private var divider: some View {
        HStack {
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)

            Text("または")
                .font(.scaledCaption())
                .foregroundStyle(secondaryColor)
                .padding(.horizontal, Spacing.sm)

            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
        }
        .padding(.vertical, Spacing.md)
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
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text("Googleでログイン")
                        .font(.scaledBodyMedium().weight(.medium))
                }
                .foregroundStyle(primaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(LoginSNSButtonStyle(isRecommended: isRecommended))
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
                label: .signIn,
                isDisabled: isLoading || !connectivity.isOnline,
                isRecommended: isRecommended
            ) { result in
                handleAppleSignIn(result)
            }
        }
    }

    private var signUpLink: some View {
        HStack {
            Text("アカウントをお持ちでない方")
                .font(.scaledBodySmall())
                .foregroundStyle(secondaryColor)

            NavigationLink {
                SignUpView()
            } label: {
                Text("新規登録")
                    .font(.scaledBodySmall().weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
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

    private var canSendEmailOTP: Bool {
        isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func sendEmailOTP() {
        guard canSendEmailOTP else { return }
        isEmailFocused = false
        errorMessage = nil
        showRelayGuidance = false
        isLoading = true
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            let result = await accountSession.sendEmailOTP(
                email: mail,
                purpose: .login,
                displayName: nil,
                isOnline: connectivity.isOnline
            )
            await MainActor.run {
                isLoading = false
                switch result {
                case .success:
                    otpChallenge = EmailOTPChallenge(email: mail, purpose: .login)
                case .failure(let error):
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
        colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.1)
    }
}

// MARK: - ボタンスタイル

private struct LoginAccentButtonStyle: ButtonStyle {
    let isEnabled: Bool
    var isRecommended: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isEnabled ? Color.accentColor : Color.gray.opacity(0.5))
            }
            .glassEffect(isEnabled ? .regular.interactive() : .regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay {
                if isRecommended, isEnabled {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct LoginSNSButtonStyle: ButtonStyle {
    var isRecommended: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.clear)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            .overlay {
                if isRecommended {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
