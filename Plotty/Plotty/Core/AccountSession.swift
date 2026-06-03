import SwiftUI

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
    
    // 本実装時削除: 開発用サンプルアカウント（Supabase 接続後は API から取得）
    static let samples: [PlottyAccount] = [
        PlottyAccount(
            id: UUID(uuidString: "A1000001-0000-4000-8000-000000000001")!,
            displayName: "メインアカウント",
            email: "main@plotty.app",
            provider: .google
        ),
        PlottyAccount(
            id: UUID(uuidString: "A1000002-0000-4000-8000-000000000002")!,
            displayName: "仕事用",
            email: "work@plotty.app",
            provider: .apple
        ),
        PlottyAccount(
            id: UUID(uuidString: "A1000003-0000-4000-8000-000000000003")!,
            displayName: "個人用",
            email: "personal@plotty.app",
            provider: .email
        ),
    ]
}

// MARK: - ログイン状態とアカウント管理
@Observable
final class AccountSession {
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let isAuthenticated = "plotty_is_authenticated"
        static let currentAccountID = "plotty_current_account_id"
        static let lastProvider = "plotty_last_provider"
        static let displayNameOverrides = "plotty_display_name_overrides"
    }
    
    // 本実装時削除: 上記 samples への参照をやめ、セッション/API 由来のアカウントに置き換え
    let availableAccounts: [PlottyAccount] = PlottyAccount.samples
    
    private(set) var isAuthenticated: Bool
    private(set) var currentAccountID: UUID?
    private(set) var lastUsedProvider: AuthProvider?
    private var displayNameOverrides: [String: String] = [:]
    
    var currentAccount: PlottyAccount? {
        guard let currentAccountID,
              var account = availableAccounts.first(where: { $0.id == currentAccountID }) else { return nil }
        if let override = displayNameOverrides[currentAccountID.uuidString] {
            account.displayName = override
        }
        return account
    }
    
    var isLoggedIn: Bool { isAuthenticated && currentAccount != nil }
    
    init() {
        isAuthenticated = defaults.bool(forKey: Keys.isAuthenticated)
        if let raw = defaults.string(forKey: Keys.currentAccountID),
           let id = UUID(uuidString: raw) {
            currentAccountID = id
        }
        if let p = defaults.string(forKey: Keys.lastProvider),
           let provider = AuthProvider(rawValue: p) {
            lastUsedProvider = provider
        }
        if let data = defaults.data(forKey: Keys.displayNameOverrides),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            displayNameOverrides = decoded
        }
        
        // 本実装時削除: デモ用の自動ログイン（PlotDebug ごと削除可）
        if PlotDebug.demoLaunchToChat || !PlotDebug.requireLoginOnLaunch,
           !isAuthenticated || currentAccount == nil {
            bootstrapDemoSession()
        }
    }
    
    // 本実装時削除: デモ用の自動ログイン
    private func bootstrapDemoSession() {
        guard let account = availableAccounts.first else { return }
        currentAccountID = account.id
        isAuthenticated = true
        lastUsedProvider = account.provider
        persist()
    }
    
    @MainActor
    func performLogin(provider: AuthProvider, email: String?, isOnline: Bool) async -> Result<Void, AuthError> {
        guard isOnline else { return .failure(.offline) }
        
        if provider == .google {
            do {
                try await AuthService.signInWithGoogle()
            } catch {
                return .failure(.providerUnavailable(provider.title))
            }
            login(provider: provider, email: email)
            return .success(())
        }
        
        // 本実装時削除: 認証 API 呼び出しの疑似遅延（Apple / メールはモック）
        try? await Task.sleep(for: .milliseconds(550))
        
        if provider == .apple, email?.lowercased().contains("privaterelay") == true {
            return .failure(.appleRelayHint)
        }
        
        if provider == .email {
            let mail = (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard isValidEmail(mail) else { return .failure(.invalidEmail) }
        }
        
        login(provider: provider, email: email)
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
        
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(mail) else { return .failure(.invalidEmail) }
        
        // 本実装時削除: サインアップ API 呼び出しの疑似遅延
        try? await Task.sleep(for: .milliseconds(650))
        
        login(provider: provider, email: mail)
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty, let id = currentAccountID {
            updateDisplayName(name, for: id)
        }
        return .success(())
    }
    
    // 本実装時削除: samples からアカウントを選ぶ仮ログイン（本番は OAuth / Supabase セッション）
    func login(provider: AuthProvider, email: String? = nil) {
        let account: PlottyAccount
        if let email, let match = availableAccounts.first(where: { $0.email == email }) {
            account = match
        } else if let first = availableAccounts.first(where: { $0.provider == provider }) {
            account = first
        } else {
            account = availableAccounts[0]
        }
        currentAccountID = account.id
        isAuthenticated = true
        lastUsedProvider = provider
        persist()
    }
    
    func signUp(displayName: String, email: String, provider: AuthProvider) {
        login(provider: provider, email: email)
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty, let id = currentAccountID {
            updateDisplayName(name, for: id)
        }
    }
    
    func switchAccount(to account: PlottyAccount) {
        currentAccountID = account.id
        isAuthenticated = true
        lastUsedProvider = account.provider
        persist()
    }
    
    func logout() {
        isAuthenticated = false
        currentAccountID = nil
        persist()
    }
    
    func deleteAccount() {
        logout()
    }
    
    func updateDisplayName(_ name: String) {
        guard let currentAccountID else { return }
        updateDisplayName(name, for: currentAccountID)
    }
    
    private func updateDisplayName(_ name: String, for accountID: UUID) {
        let trimmed = PlotInputLimits.clamp(
            name.trimmingCharacters(in: .whitespacesAndNewlines),
            max: PlotInputLimits.displayName
        )
        guard !trimmed.isEmpty else { return }
        displayNameOverrides[accountID.uuidString] = trimmed
        persist()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func persist() {
        defaults.set(isAuthenticated, forKey: Keys.isAuthenticated)
        if let currentAccountID {
            defaults.set(currentAccountID.uuidString, forKey: Keys.currentAccountID)
        } else {
            defaults.removeObject(forKey: Keys.currentAccountID)
        }
        if let lastUsedProvider {
            defaults.set(lastUsedProvider.rawValue, forKey: Keys.lastProvider)
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
