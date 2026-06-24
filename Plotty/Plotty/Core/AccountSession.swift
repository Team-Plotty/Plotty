import SwiftUI
import Supabase

// MARK: - 認証エラー
enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case offline
    case providerUnavailable(String)
    case appleRelayHint

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "メールアドレスの形式を確認してください。"
        case .offline:
            return "インターネットに接続してから、もう一度お試しください。"
        case .providerUnavailable(let provider):
            return "\(provider)でのログインに失敗しました。しばらくしてから再試行してください。"
        case .appleRelayHint:
            return "Hide My Email を使っている場合、既存アカウントと紐づいていないことがあります。別のメールアドレスでログインするか、ヘルプをご確認ください。"
        }
    }
}

// MARK: - 認証プロバイダ（本実装時: Supabase Auth と連携）
enum AuthProvider: String, CaseIterable, Identifiable, Codable {
    case google
    case apple
    case email

    var id: String { rawValue }

    var title: String {
        switch self {
        case .google: return "Google"
        case .apple: return "Apple"
        case .email: return "メール"
        }
    }

    var icon: String {
        switch self {
        case .google: return "g.circle.fill"
        case .apple: return "apple.logo"
        case .email: return "envelope.fill"
        }
    }
}

// MARK: - アカウント
struct PlottyAccount: Identifiable, Hashable, Codable {
    let id: UUID
    var displayName: String
    var email: String
    var provider: AuthProvider

    /// SwiftUI プレビュー専用（本番セッションでは Supabase `User` から生成する）。
    static let preview = PlottyAccount(
        id: UUID(uuidString: "A1000001-0000-4000-8000-000000000001")!,
        displayName: "プレビューユーザー",
        email: "preview@plotty.app",
        provider: .google
    )
}

// MARK: - ログイン状態とアカウント管理
@Observable
final class AccountSession {
    private let defaults = UserDefaults.standard
    private let supabaseEnabled: Bool
    private var authObserverTask: Task<Void, Never>?

    private enum Keys {
        static let lastProvider = "plotty_last_provider"
        static let displayNameOverrides = "plotty_display_name_overrides"
    }

    private(set) var storedAccount: PlottyAccount?
    private(set) var lastUsedProvider: AuthProvider?
    private var displayNameOverrides: [String: String] = [:]

    /// ログイン中のアカウント一覧（D1 時点では Supabase セッション 1 件のみ）。
    var availableAccounts: [PlottyAccount] {
        guard let currentAccount else { return [] }
        return [currentAccount]
    }

    var currentAccount: PlottyAccount? {
        guard var account = storedAccount else { return nil }
        if let override = displayNameOverrides[account.id.uuidString] {
            account.displayName = override
        }
        return account
    }

    var isAuthenticated: Bool { storedAccount != nil }

    var isLoggedIn: Bool { isAuthenticated }

    init(supabaseEnabled: Bool = true) {
        self.supabaseEnabled = supabaseEnabled

        if let provider = defaults.string(forKey: Keys.lastProvider),
           let decoded = AuthProvider(rawValue: provider) {
            lastUsedProvider = decoded
        }
        if let data = defaults.data(forKey: Keys.displayNameOverrides),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            displayNameOverrides = decoded
        }

        if PlotDebug.demoLaunchToChat, supabaseEnabled {
            bootstrapDemoSession()
        } else if supabaseEnabled {
            startAuthObservation()
        }
    }

    deinit {
        authObserverTask?.cancel()
    }

    #if DEBUG
    /// プレビュー用（Supabase には接続しない）。
    static func preview(loggedIn: Bool = true, account: PlottyAccount = .preview) -> AccountSession {
        let session = AccountSession(supabaseEnabled: false)
        if loggedIn {
            session.storedAccount = account
            session.lastUsedProvider = account.provider
        }
        return session
    }
    #endif

    @MainActor
    func performLogin(provider: AuthProvider, email: String?, isOnline: Bool) async -> Result<Void, AuthError> {
        guard isOnline else { return .failure(.offline) }

        if provider == .google {
            return await performSupabaseOAuthLogin(provider: provider, email: email)
        }

        if provider == .apple {
            // Apple は PlotAppleSignInButton → completeSupabaseSignIn 経由
            return .failure(.providerUnavailable(provider.title))
        }

        // D3 で Supabase 接続予定（メールはモック）
        try? await Task.sleep(for: .milliseconds(550))

        if provider == .email {
            let mail = (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard isValidEmail(mail) else { return .failure(.invalidEmail) }
        }

        loginWithMock(provider: provider, email: email)
        return .success(())
    }

    @MainActor
    func performSignUp(
        displayName: String,
        email: String,
        provider: AuthProvider,
        isOnline: Bool
    ) async -> Result<Void, AuthError> {
        guard isOnline else { return .failure(.offline) }

        if provider == .google {
            let result = await performSupabaseOAuthLogin(provider: provider, email: email)
            if case .success = result {
                applySignUpDisplayName(displayName)
            }
            return result
        }

        if provider == .apple {
            return .failure(.providerUnavailable(provider.title))
        }

        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(mail) else { return .failure(.invalidEmail) }

        // D3 で Supabase 接続予定
        try? await Task.sleep(for: .milliseconds(650))

        loginWithMock(provider: provider, email: mail)
        applySignUpDisplayName(displayName)
        return .success(())
    }

    /// Sign in with Apple / OAuth 完了後に Supabase セッションを反映する。
    @MainActor
    func completeSupabaseSignIn(_ session: Session, displayNameOverride: String? = nil) -> Result<Void, AuthError> {
        applySupabaseSession(session)
        applySignUpDisplayName(displayNameOverride)
        return .success(())
    }

    func switchAccount(to account: PlottyAccount) {
        guard storedAccount?.id == account.id else { return }
        lastUsedProvider = account.provider
        persistPreferences()
    }

    func logout() {
        Task { @MainActor in
            await performLogout()
        }
    }

    func deleteAccount() {
        logout()
    }

    func updateDisplayName(_ name: String) {
        guard let accountID = storedAccount?.id else { return }
        updateDisplayName(name, for: accountID)
    }

    // MARK: - Supabase 連携

    @MainActor
    private func startAuthObservation() {
        authObserverTask = Task { @MainActor in
            for await (event, session) in SupabaseManager.client.auth.authStateChanges {
                guard !Task.isCancelled else { break }
                switch event {
                case .signedOut, .userDeleted:
                    clearLocalSession()
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    if let session {
                        applySupabaseSession(session)
                    } else {
                        clearLocalSession()
                    }
                case .passwordRecovery, .mfaChallengeVerified:
                    break
                }
            }
        }
    }

    @MainActor
    private func applySupabaseSession(_ session: Session) {
        var account = PlottyAccountMapper.makeAccount(from: session.user)
        if let override = displayNameOverrides[account.id.uuidString] {
            account.displayName = override
        }
        storedAccount = account
        lastUsedProvider = account.provider
        persistPreferences()
    }

    @MainActor
    private func performLogout() async {
        if supabaseEnabled {
            try? await AuthService.signOut()
        }
        clearLocalSession()
    }

    @MainActor
    private func clearLocalSession() {
        storedAccount = nil
        persistPreferences()
    }

    // MARK: - モック（D3 までの暫定）

    @MainActor
    private func performSupabaseOAuthLogin(provider: AuthProvider, email: String?) async -> Result<Void, AuthError> {
        guard supabaseEnabled else {
            loginWithMock(provider: provider, email: email)
            return .success(())
        }
        do {
            let session = try await AuthService.signInWithGoogle()
            applySupabaseSession(session)
            return .success(())
        } catch {
            return .failure(.providerUnavailable(provider.title))
        }
    }

    @MainActor
    private func applySignUpDisplayName(_ displayName: String?) {
        let name = (displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let id = storedAccount?.id else { return }
        updateDisplayName(name, for: id)
    }

    @MainActor
    private func loginWithMock(provider: AuthProvider, email: String?) {
        let mail = (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedEmail = mail.isEmpty ? "mock@plotty.app" : mail
        let localPart = resolvedEmail.split(separator: "@").first.map(String.init) ?? "ユーザー"
        storedAccount = PlottyAccount(
            id: UUID(),
            displayName: localPart,
            email: resolvedEmail,
            provider: provider
        )
        lastUsedProvider = provider
        persistPreferences()
    }

    // 本実装時削除: デモ用の自動ログイン
    private func bootstrapDemoSession() {
        storedAccount = PlottyAccount.preview
        lastUsedProvider = PlottyAccount.preview.provider
        persistPreferences()
    }

    private func updateDisplayName(_ name: String, for accountID: UUID) {
        let trimmed = PlotInputLimits.clamp(
            name.trimmingCharacters(in: .whitespacesAndNewlines),
            max: PlotInputLimits.displayName
        )
        guard !trimmed.isEmpty else { return }
        displayNameOverrides[accountID.uuidString] = trimmed
        persistPreferences()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func persistPreferences() {
        if let lastUsedProvider {
            defaults.set(lastUsedProvider.rawValue, forKey: Keys.lastProvider)
        } else {
            defaults.removeObject(forKey: Keys.lastProvider)
        }
        if let data = try? JSONEncoder().encode(displayNameOverrides) {
            defaults.set(data, forKey: Keys.displayNameOverrides)
        }
    }
}

private struct AccountSessionKey: EnvironmentKey {
    static let defaultValue = AccountSession()
}

extension EnvironmentValues {
    var accountSession: AccountSession {
        get { self[AccountSessionKey.self] }
        set { self[AccountSessionKey.self] = newValue }
    }
}
