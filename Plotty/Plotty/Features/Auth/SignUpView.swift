import SwiftUI

// MARK: - 新規登録画面
struct SignUpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accountSession) private var accountSession
    @Environment(\.appSettings) private var appSettings
    @Environment(\.connectivity) private var connectivity
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var agreedToTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTimezoneID: String = ""
    
    private let timezoneOptions: [String] = [
        "Asia/Tokyo",
        "America/Los_Angeles",
        "America/New_York",
        "Europe/London",
        "UTC",
    ]
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("新規登録")
                        .font(.scaledTitleLarge())
                        .foregroundStyle(primaryColor)
                    
                    if !connectivity.isOnline {
                        PlotOfflineBanner()
                    }
                    
                    if let errorMessage {
                        PlotErrorBanner(message: errorMessage, onRetry: nil)
                    }
                    
                    PlotFormCard(title: "プロフィール（任意）") {
                        TextField("表示名", text: $displayName)
                            .font(.scaledBodyLarge())
                            .foregroundStyle(primaryColor)
                            .onChange(of: displayName) { _, newValue in
                                displayName = PlotInputLimits.clamp(newValue, max: PlotInputLimits.displayName)
                            }
                        PlotCharacterCountFooter(
                            current: displayName.count,
                            maximum: PlotInputLimits.displayName
                        )
                    }
                    
                    PlotFormCard(title: "アカウント") {
                        TextField("メールアドレス", text: $email)
                            .font(.scaledBodyLarge())
                            .foregroundStyle(primaryColor)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .onChange(of: email) { _, newValue in
                                email = PlotInputLimits.clamp(newValue, max: PlotInputLimits.title)
                            }
                        
                        Picker("タイムゾーン", selection: $selectedTimezoneID) {
                            ForEach(timezoneOptions, id: \.self) { id in
                                Text(timezoneLabel(id)).tag(id)
                            }
                        }
                    }
                    
                    PlotFormCard {
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
                    }
                    
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
                            .disabled(!canSubmit || isLoading || !connectivity.isOnline)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.vertical, Spacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedTimezoneID.isEmpty {
                selectedTimezoneID = appSettings.timezoneIdentifier
            }
        }
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
        appSettings.timezoneIdentifier = selectedTimezoneID
        
        Task {
            let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = await accountSession.performSignUp(
                displayName: name.isEmpty ? "新規ユーザー" : name,
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
    
    private func timezoneLabel(_ id: String) -> String {
        let tz = TimeZone(identifier: id) ?? .current
        return "\(id.replacingOccurrences(of: "_", with: " ")) (\(tz.secondsFromGMT() / 3600)h)"
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
            .environment(\.connectivity, ConnectivityMonitor())
    }
}
