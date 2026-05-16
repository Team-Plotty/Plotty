import SwiftUI

// MARK: - 認証プロバイダ（Supabase 接続前の UI 用）
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
    /// デモ用: 起動時にログイン画面を出さず、サンプルアカウントでホームへ
    private static let demoSkipsLoginOnLaunch = true
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let isAuthenticated = "plotty_is_authenticated"
        static let currentAccountID = "plotty_current_account_id"
        static let lastProvider = "plotty_last_provider"
    }
    
    let availableAccounts: [PlottyAccount] = PlottyAccount.samples
    
    private(set) var isAuthenticated: Bool
    private(set) var currentAccountID: UUID?
    private(set) var lastUsedProvider: AuthProvider?
    
    var currentAccount: PlottyAccount? {
        guard let currentAccountID else { return nil }
        return availableAccounts.first { $0.id == currentAccountID }
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
        
        if Self.demoSkipsLoginOnLaunch, !isAuthenticated || currentAccount == nil {
            bootstrapDemoSession()
        }
    }
    
    private func bootstrapDemoSession() {
        guard let account = availableAccounts.first else { return }
        currentAccountID = account.id
        isAuthenticated = true
        lastUsedProvider = account.provider
        persist()
    }
    
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
        // API 接続前: ローカル表示のみ（サンプルは不変）
        _ = name
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
