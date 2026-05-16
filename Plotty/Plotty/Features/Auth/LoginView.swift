import SwiftUI

// MARK: - ログイン画面
struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    
    @State private var email = ""
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        header
                        
                        if let errorMessage {
                            PlotErrorBanner(message: errorMessage, onRetry: nil)
                        }
                        
                        if let last = accountSession.lastUsedProvider {
                            Text("前回: \(last.title) でログイン")
                                .font(.scaledCaption())
                                .foregroundStyle(secondaryColor)
                        }
                        
                        providerButtons
                        
                        emailSection
                        
                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text("新規登録へ")
                                .font(.scaledBodyMedium().weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        
                        legalLinks
                    }
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.vertical, Spacing.xl)
                }
            }
            .sheet(isPresented: $showTerms) {
                NavigationStack {
                    LegalDocumentView(kind: .termsOfService)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPrivacy) {
                NavigationStack {
                    LegalDocumentView(kind: .privacyPolicy)
                }
                .presentationDetents([.medium, .large])
            }
            .overlay {
                if isLoading {
                    PlotLoadingOverlay(message: "ログイン中…")
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Plotty")
                .font(.scaledDisplayMedium())
                .foregroundStyle(primaryColor)
            Text("チャットから予定・タスク・メモを整理")
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.lg)
    }
    
    private var providerButtons: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(AuthProvider.allCases) { provider in
                Button {
                    login(with: provider)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: provider.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 28)
                        Text("\(provider.title)でログイン")
                            .font(.scaledBodyLarge())
                        Spacer()
                    }
                    .foregroundStyle(primaryColor)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("メールアドレス")
                .font(.scaledLabelMedium())
                .foregroundStyle(secondaryColor)
            
            TextField("", text: $email, prompt: Text("name@example.com").foregroundStyle(placeholderColor))
                .font(.scaledBodyMedium())
                .foregroundStyle(primaryColor)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .plotInputCapsuleGlass()
            
            Button("メールでログイン") {
                login(with: .email)
            }
            .filledButtonStyle()
            .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private var legalLinks: some View {
        HStack(spacing: Spacing.md) {
            Button("利用規約") { showTerms = true }
            Button("プライバシー") { showPrivacy = true }
        }
        .font(.scaledCaption())
        .foregroundStyle(secondaryColor)
        .frame(maxWidth: .infinity)
    }
    
    private func login(with provider: AuthProvider) {
        errorMessage = nil
        isLoading = true
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            await MainActor.run {
                let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                accountSession.login(provider: provider, email: mail.isEmpty ? nil : mail)
                isLoading = false
            }
        }
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var placeholderColor: Color {
        colorScheme == .dark ? Color.darkInputPlaceholder : Color.lightInputPlaceholder
    }
}

#Preview {
    LoginView()
        .environment(\.accountSession, AccountSession())
}
