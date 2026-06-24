import SwiftUI

// MARK: - ログイン画面
struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity
    
    @State private var email = ""
    @State private var password = ""
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email, password
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
                        
                        if let errorMessage {
                            PlotErrorBanner(message: errorMessage, onRetry: nil)
                        }
                        
                        loginForm
                        
                        divider
                        
                        snsLoginButtons
                        
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
            .overlay {
                if isLoading {
                    PlotLoadingOverlay(message: "ログイン中…")
                }
            }
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
    
    private var loginForm: some View {
        VStack(spacing: Spacing.md) {
            // メールアドレス入力
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
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .frame(minHeight: 50)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.clear)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
            }
            
            // パスワード入力
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("パスワード")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                
                SecureField("パスワードを入力", text: $password)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(primaryColor)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit { loginWithEmail() }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .frame(minHeight: 50)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.clear)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
            }
            
            // ログインボタン
            Button(action: loginWithEmail) {
                Text("ログイン")
                    .font(.scaledBodyLarge().weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .disabled(!canLogin || isLoading)
            .buttonStyle(LiquidGlassAccentButtonStyle(isEnabled: canLogin && !isLoading))
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
            // Google
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
            .buttonStyle(LiquidGlassSNSButtonStyle())
            .disabled(isLoading || !connectivity.isOnline)
            
            // Apple
            Button {
                login(with: .apple)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20))
                    Text("Appleでログイン")
                        .font(.scaledBodyMedium().weight(.medium))
                }
                .foregroundStyle(primaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(LiquidGlassSNSButtonStyle())
            .disabled(isLoading || !connectivity.isOnline)
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
    
    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
    
    private func loginWithEmail() {
        guard canLogin else { return }
        focusedField = nil
        login(with: .email)
    }
    
    private func login(with provider: AuthProvider) {
        errorMessage = nil
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
    LoginView()
        .environment(\.accountSession, AccountSession.preview())
        .environment(\.connectivity, ConnectivityMonitor())
}
