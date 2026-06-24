import AuthenticationServices
import SwiftUI
import Supabase

// MARK: - 新規登録画面
struct SignUpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case username, email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    
                    if !connectivity.isOnline {
                        PlotOfflineBanner()
                    }
                    
                    if let errorMessage {
                        PlotErrorBanner(message: errorMessage, onRetry: nil)
                    }
                    
                    signUpForm
                    
                    termsSection
                    
                    signUpButton
                    
                    divider
                    
                    snsSignUpButtons
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.vertical, Spacing.xl)
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
                PlotLoadingOverlay(message: "登録中…")
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("新規登録")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(primaryColor)
            
            Text("アカウントを作成してPlottyを始めましょう")
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryColor)
        }
        .padding(.top, Spacing.md)
    }
    
    private var signUpForm: some View {
        VStack(spacing: Spacing.md) {
            // ユーザー名
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("ユーザー名")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                
                TextField("ユーザー名を入力", text: $username)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(primaryColor)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                    .onChange(of: username) { _, newValue in
                        username = PlotInputLimits.clamp(newValue, max: PlotInputLimits.displayName)
                    }
                    .modifier(InputFieldModifier(colorScheme: colorScheme))
            }
            
            // メールアドレス
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("メールアドレス")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                
                TextField("example@email.com", text: $email)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(primaryColor)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .modifier(InputFieldModifier(colorScheme: colorScheme))
            }
            
            // パスワード
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("パスワード")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                
                SecureField("8文字以上", text: $password)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(primaryColor)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .confirmPassword }
                    .modifier(InputFieldModifier(colorScheme: colorScheme))
                
                if !password.isEmpty && password.count < 8 {
                    Text("パスワードは8文字以上で入力してください")
                        .font(.scaledCaption())
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
            
            // パスワード確認
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("パスワード（確認）")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                
                SecureField("パスワードを再入力", text: $confirmPassword)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(primaryColor)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.done)
                    .onSubmit { signUpWithEmail() }
                    .modifier(InputFieldModifier(colorScheme: colorScheme))
                
                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("パスワードが一致しません")
                        .font(.scaledCaption())
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
    }
    
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Toggle(isOn: $agreedToTerms) {
                Text("利用規約とプライバシーポリシーに同意する")
                    .font(.scaledBodySmall())
                    .foregroundStyle(primaryColor)
            }
            .tint(.accentColor)
            
            HStack(spacing: Spacing.md) {
                Button("利用規約を見る") { showTerms = true }
                Button("プライバシーポリシーを見る") { showPrivacy = true }
            }
            .font(.scaledCaption())
            .foregroundStyle(Color.accentColor)
        }
        .padding(.top, Spacing.sm)
    }
    
    private var signUpButton: some View {
        Button(action: signUpWithEmail) {
            Text("アカウントを作成")
                .font(.scaledBodyLarge().weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .disabled(!canSubmit || isLoading)
        .buttonStyle(LiquidGlassAccentButtonStyle(isEnabled: canSubmit && !isLoading))
        .padding(.top, Spacing.md)
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
    
    private var snsSignUpButtons: some View {
        VStack(spacing: Spacing.sm) {
            // Google
            Button {
                signUp(with: .google)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text("Googleで登録")
                        .font(.scaledBodyMedium().weight(.medium))
                }
                .foregroundStyle(primaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(LiquidGlassSNSButtonStyle())
            .disabled(isLoading || !connectivity.isOnline || !agreedToTerms)
            
            // Apple（ネイティブ Sign in with Apple）
            PlotAppleSignInButton(
                label: .signUp,
                isDisabled: isLoading || !connectivity.isOnline || !agreedToTerms
            ) { result in
                handleAppleSignUp(result)
            }
            
            if !agreedToTerms {
                Text("SNSで登録するには利用規約への同意が必要です")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var canSubmit: Bool {
        agreedToTerms &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    private func signUpWithEmail() {
        guard canSubmit else { return }
        focusedField = nil
        signUp(with: .email)
    }
    
    private func signUp(with provider: AuthProvider) {
        guard agreedToTerms else {
            errorMessage = "利用規約に同意してください。"
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = await accountSession.performSignUp(
                displayName: name.isEmpty ? "ユーザー" : name,
                email: mail,
                provider: provider,
                isOnline: connectivity.isOnline
            )
            await MainActor.run {
                isLoading = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleAppleSignUp(_ result: Result<AppleSignInPayload, Error>) {
        guard agreedToTerms else {
            errorMessage = "利用規約に同意してください。"
            return
        }

        errorMessage = nil
        isLoading = true
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            let authResult: Result<Void, AuthError>
            switch result {
            case .success(let payload):
                let resolvedName = name.isEmpty ? payload.suggestedDisplayName : name
                authResult = accountSession.completeSupabaseSignIn(
                    payload.session,
                    displayNameOverride: resolvedName
                )
            case .failure:
                authResult = .failure(.providerUnavailable(AuthProvider.apple.title))
            }
            await MainActor.run {
                isLoading = false
                switch authResult {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
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
    
    private var inputBackgroundColor: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.04)
    }
    
    private var inputBorderColor: Color {
        colorScheme == .dark ? .white.opacity(0.15) : .black.opacity(0.1)
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.1)
    }
}

// MARK: - 入力フィールドのスタイル（Liquid Glass）
private struct InputFieldModifier: ViewModifier {
    let colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 50)
            .background {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
    }
}

// MARK: - Liquid Glass ボタンスタイル（アクセント）
private struct LiquidGlassAccentButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isEnabled ? Color.accentColor : Color.gray.opacity(0.5))
            }
            .glassEffect(isEnabled ? .regular.interactive() : .regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass ボタンスタイル（SNS）
private struct LiquidGlassSNSButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.clear)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environment(\.accountSession, AccountSession.preview())
            .environment(\.connectivity, ConnectivityMonitor())
    }
}
