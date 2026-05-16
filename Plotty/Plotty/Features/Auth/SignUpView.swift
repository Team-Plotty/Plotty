import SwiftUI

// MARK: - 新規登録画面
struct SignUpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.appSettings) private var appSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var agreedToTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("新規登録")
                        .font(.scaledTitleLarge())
                        .foregroundStyle(primaryColor)
                    
                    if let errorMessage {
                        PlotErrorBanner(message: errorMessage, onRetry: nil)
                    }
                    
                    TextField("表示名（任意）", text: $displayName)
                        .font(.scaledBodyLarge())
                        .foregroundStyle(primaryColor)
                        .padding(Spacing.md)
                        .plotInputCapsuleGlass()
                    
                    TextField("メールアドレス", text: $email)
                        .font(.scaledBodyLarge())
                        .foregroundStyle(primaryColor)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(Spacing.md)
                        .plotInputCapsuleGlass()
                    
                    Text("タイムゾーン: \(appSettings.timezone.identifier)")
                        .font(.scaledCaption())
                        .foregroundStyle(secondaryColor)
                    
                    Toggle(isOn: $agreedToTerms) {
                        Text("利用規約とプライバシーポリシーに同意する")
                            .font(.scaledBodySmall())
                            .foregroundStyle(primaryColor)
                    }
                    .tint(.accentColor)
                    
                    HStack(spacing: Spacing.md) {
                        Button("利用規約") { showTerms = true }
                        Button("プライバシー") { showPrivacy = true }
                    }
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                    
                    VStack(spacing: Spacing.sm) {
                        ForEach(AuthProvider.allCases) { provider in
                            Button {
                                signUp(with: provider)
                            } label: {
                                Text("\(provider.title)で登録")
                                    .font(.scaledBodyLarge())
                                    .frame(maxWidth: .infinity)
                            }
                            .filledButtonStyle()
                            .disabled(!canSubmit)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.vertical, Spacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTerms) {
            NavigationStack { LegalDocumentView(kind: .termsOfService) }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack { LegalDocumentView(kind: .privacyPolicy) }
                .presentationDetents([.medium, .large])
        }
        .overlay {
            if isLoading {
                PlotLoadingOverlay(message: "登録中…")
            }
        }
    }
    
    private var canSubmit: Bool {
        agreedToTerms && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func signUp(with provider: AuthProvider) {
        guard canSubmit else {
            errorMessage = "同意とメールアドレスを確認してください。"
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            await MainActor.run {
                let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                accountSession.signUp(
                    displayName: name.isEmpty ? "新規ユーザー" : name,
                    email: mail,
                    provider: provider
                )
                isLoading = false
                dismiss()
            }
        }
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environment(\.accountSession, AccountSession())
            .environment(\.appSettings, AppSettings())
    }
}
