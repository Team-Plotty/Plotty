import SwiftUI
import Supabase

// MARK: - 認証エラー
enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case offline
    case providerUnavailable(String)
    case appleRelayHint
    case otpDeliveryFailed
    case otpVerificationFailed
    case invalidCredentials
    case emailAlreadyRegistered
    case weakPassword
    /// サーバー側でメール確認がオンのままのときに起きる（登録はできたがセッションが返らない）。
    case emailConfirmationRequired
    case signUpFailed
    case passwordUpdateFailed
    case logoutFailed
    case deleteAccountFailed

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "メールアドレスの形式を確認してください。"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません。"
        case .emailAlreadyRegistered:
            return "このメールアドレスはすでに登録されています。ログイン画面からログインしてください。"
        case .weakPassword:
            return "パスワードは\(PlotInputLimits.passwordMinimum)文字以上で入力してください。"
        case .emailConfirmationRequired:
            return "確認メールを送信しました。メール内のリンクを開いてから、ログインしてください。"
        case .signUpFailed:
            return "登録に失敗しました。通信状態を確認して、もう一度お試しください。"
        case .passwordUpdateFailed:
            return "パスワードの設定に失敗しました。通信状態を確認して、もう一度お試しください。"
        case .offline:
            return "インターネットに接続してから、もう一度お試しください。"
        case .providerUnavailable(let provider):
            return "\(provider)でのログインに失敗しました。しばらくしてから再試行してください。"
        case .appleRelayHint:
            return "Hide My Email を使っている場合、既存アカウントと紐づいていないことがあります。別のメールアドレスでログインするか、ヘルプをご確認ください。"
        case .otpDeliveryFailed:
            return "認証コードの送信に失敗しました。メールアドレスを確認して、もう一度お試しください。"
        case .otpVerificationFailed:
            return "認証コードが正しくないか、有効期限が切れています。もう一度お試しください。"
        case .logoutFailed:
            return "ログアウトに失敗しました。通信状態を確認して、もう一度お試しください。"
        case .deleteAccountFailed:
            return "アカウント削除に失敗しました。しばらくしてから再試行してください。"
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

    /// ログイン後に `public.users` から設定を引く（`UserSettingsSync` が設定する）。
    @ObservationIgnored
    var onProfileSyncNeeded: (@MainActor () async -> Void)?

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

        #if DEBUG
        if PlotDebug.demoLaunchToChat, supabaseEnabled {
            bootstrapDemoSession()
        } else if supabaseEnabled {
            startAuthObservation()
        }
        #else
        if supabaseEnabled {
            startAuthObservation()
        }
        #endif
    }

    deinit {
        authObserverTask?.cancel()
    }

    #if DEBUG
    /// プレビュー用（Supabase には接続しない）。
    static func preview(
        loggedIn: Bool = true,
        account: PlottyAccount = .preview,
        lastProvider: AuthProvider? = nil
    ) -> AccountSession {
        let session = AccountSession(supabaseEnabled: false)
        if loggedIn {
            session.storedAccount = account
            session.lastUsedProvider = lastProvider ?? account.provider
        } else if let lastProvider {
            session.lastUsedProvider = lastProvider
        }
        return session
    }
    #endif

    @MainActor
    func performLogin(provider: AuthProvider, email: String?, isOnline: Bool) async -> Result<Void, AuthError> {
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: "login", error: .offline, provider: provider)
            return .failure(.offline)
        }

        if provider == .google {
            return await performSupabaseOAuthLogin(provider: provider, email: email)
        }

        if provider == .apple {
            // Apple は PlotAppleSignInButton → completeSupabaseSignIn 経由
            return .failure(.providerUnavailable(provider.title))
        }

        if provider == .email {
            return .failure(.providerUnavailable(provider.title))
        }

        loginWithMock(provider: provider, email: email)
        PlotAnalytics.trackAuthSuccess(action: "login", provider: provider)
        return .success(())
    }

    // MARK: - メール＋パスワード

    /// メールアドレスとパスワードでアカウントを作成し、そのままログイン状態にする。
    /// 表示名は登録時には受け取らず、設定画面から任意で登録してもらう。
    @MainActor
    func signUpWithPassword(email: String, password: String, isOnline: Bool) async -> Result<Void, AuthError> {
        let action = "signup_password"
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: action, error: .offline, provider: .email)
            return .failure(.offline)
        }
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(mail) else {
            PlotAnalytics.trackAuthFailure(action: action, error: .invalidEmail, provider: .email)
            return .failure(.invalidEmail)
        }
        guard password.count >= PlotInputLimits.passwordMinimum else {
            PlotAnalytics.trackAuthFailure(action: action, error: .weakPassword, provider: .email)
            return .failure(.weakPassword)
        }

        guard supabaseEnabled else {
            loginWithMock(provider: .email, email: mail)
            PlotAnalytics.trackAuthSuccess(action: "signup", provider: .email)
            return .success(())
        }

        do {
            guard let session = try await AuthService.signUpWithPassword(email: mail, password: password) else {
                PlotAnalytics.trackAuthFailure(action: action, error: .emailConfirmationRequired, provider: .email)
                return .failure(.emailConfirmationRequired)
            }
            return completeSupabaseSignIn(session, isSignUp: true)
        } catch {
            let mapped = Self.mapPasswordAuthError(error, fallback: .signUpFailed)
            PlotAnalytics.trackAuthFailure(action: action, error: mapped, provider: .email)
            return .failure(mapped)
        }
    }

    /// メールアドレスとパスワードでログインする。
    @MainActor
    func signInWithPassword(email: String, password: String, isOnline: Bool) async -> Result<Void, AuthError> {
        let action = "login_password"
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: action, error: .offline, provider: .email)
            return .failure(.offline)
        }
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(mail) else {
            PlotAnalytics.trackAuthFailure(action: action, error: .invalidEmail, provider: .email)
            return .failure(.invalidEmail)
        }

        guard supabaseEnabled else {
            loginWithMock(provider: .email, email: mail)
            PlotAnalytics.trackAuthSuccess(action: "login", provider: .email)
            return .success(())
        }

        do {
            let session = try await AuthService.signInWithPassword(email: mail, password: password)
            return completeSupabaseSignIn(session)
        } catch {
            let mapped = Self.mapPasswordAuthError(error, fallback: .providerUnavailable(AuthProvider.email.title))
            PlotAnalytics.trackAuthFailure(action: action, error: mapped, provider: .email)
            return .failure(mapped)
        }
    }

    /// ログイン中アカウントのパスワードを設定・変更する（認証コードでログインした後の再設定にも使う）。
    @MainActor
    func updatePassword(_ password: String, isOnline: Bool) async -> Result<Void, AuthError> {
        let action = "password_update"
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: action, error: .offline, provider: storedAccount?.provider)
            return .failure(.offline)
        }
        guard password.count >= PlotInputLimits.passwordMinimum else {
            return .failure(.weakPassword)
        }
        guard supabaseEnabled else { return .success(()) }

        do {
            try await AuthService.updatePassword(password)
            return .success(())
        } catch {
            let mapped = Self.mapPasswordAuthError(error, fallback: .passwordUpdateFailed)
            PlotAnalytics.trackAuthFailure(action: action, error: mapped, provider: storedAccount?.provider)
            return .failure(mapped)
        }
    }

    /// Supabase Auth のエラーコードを、画面に出すアプリのエラーへ変換する。
    private static func mapPasswordAuthError(_ error: Error, fallback: AuthError) -> AuthError {
        guard let authError = error as? Auth.AuthError else { return fallback }
        switch authError.errorCode {
        case .invalidCredentials:
            return .invalidCredentials
        case .userAlreadyExists, .emailExists:
            return .emailAlreadyRegistered
        case .weakPassword:
            return .weakPassword
        case .emailNotConfirmed:
            return .emailConfirmationRequired
        default:
            return fallback
        }
    }

    // MARK: - メール OTP（パスワードを忘れたときのログイン）

    /// 既存アカウントのメールに OTP / マジックリンクを送信する。
    @MainActor
    func sendEmailOTP(email: String, isOnline: Bool) async -> Result<Void, AuthError> {
        let action = "login_otp_send"
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: action, error: .offline, provider: .email)
            return .failure(.offline)
        }

        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(mail) else {
            PlotAnalytics.trackAuthFailure(action: action, error: .invalidEmail, provider: .email)
            return .failure(.invalidEmail)
        }

        guard supabaseEnabled else { return .success(()) }

        do {
            try await AuthService.sendEmailOTP(email: mail)
            return .success(())
        } catch {
            PlotAnalytics.trackAuthFailure(action: action, error: .otpDeliveryFailed, provider: .email)
            return .failure(.otpDeliveryFailed)
        }
    }

    /// メール OTP を検証してセッションを反映する。
    @MainActor
    func verifyEmailOTP(email: String, code: String, isOnline: Bool) async -> Result<Void, AuthError> {
        let action = "login_otp_verify"
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: action, error: .offline, provider: .email)
            return .failure(.offline)
        }

        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(mail), token.count == 6 else {
            PlotAnalytics.trackAuthFailure(action: action, error: .otpVerificationFailed, provider: .email)
            return .failure(.otpVerificationFailed)
        }

        guard supabaseEnabled else {
            loginWithMock(provider: .email, email: mail)
            PlotAnalytics.trackAuthSuccess(action: "login", provider: .email)
            return .success(())
        }

        do {
            let session = try await AuthService.verifyEmailOTP(email: mail, token: token)
            return completeSupabaseSignIn(session)
        } catch {
            PlotAnalytics.trackAuthFailure(action: action, error: .otpVerificationFailed, provider: .email)
            return .failure(.otpVerificationFailed)
        }
    }

    // MARK: - SNS で新規登録

    /// Google で新規登録する（表示名は Google のプロフィール名を使い、変更は設定画面から行う）。
    @MainActor
    func performSignUp(email: String, provider: AuthProvider, isOnline: Bool) async -> Result<Void, AuthError> {
        guard isOnline else { return .failure(.offline) }

        if provider == .google {
            let result = await performSupabaseOAuthLogin(
                provider: provider,
                email: email,
                pullProfile: false
            )
            if case .success = result {
                await syncSignUpProfile(displayNameOverride: nil)
            }
            return result
        }

        if provider == .apple || provider == .email {
            return .failure(.providerUnavailable(provider.title))
        }

        loginWithMock(provider: provider, email: email)
        return .success(())
    }

    /// Sign in with Apple / OAuth 完了後に Supabase セッションを反映する。
    @MainActor
    func completeSupabaseSignIn(
        _ session: Session,
        displayNameOverride: String? = nil,
        isSignUp: Bool = false
    ) -> Result<Void, AuthError> {
        applySupabaseSession(session, pullProfile: !isSignUp)
        applySignUpDisplayName(displayNameOverride)
        if isSignUp {
            Task { @MainActor in
                await syncSignUpProfile(displayNameOverride: displayNameOverride)
            }
        }
        if let provider = storedAccount?.provider {
            PlotAnalytics.trackAuthSuccess(action: isSignUp ? "signup" : "login", provider: provider)
        }
        return .success(())
    }

    func switchAccount(to account: PlottyAccount) {
        guard storedAccount?.id == account.id else { return }
        lastUsedProvider = account.provider
        persistPreferences()
    }

    @MainActor
    func logout(isOnline: Bool) async -> Result<Void, AuthError> {
        await performLogout(isOnline: isOnline)
    }

    @MainActor
    func deleteAccount(isOnline: Bool) async -> Result<Void, AuthError> {
        await performDeleteAccount(isOnline: isOnline)
    }

    func updateDisplayName(_ name: String) {
        guard let accountID = storedAccount?.id else { return }
        updateDisplayName(name, for: accountID)
    }

    /// クラウドの `display_name` を端末へ反映する。
    func applyRemoteDisplayName(_ name: String) {
        updateDisplayName(name)
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
                case .initialSession, .signedIn:
                    if let session {
                        applySupabaseSession(session, pullProfile: true)
                    } else {
                        clearLocalSession()
                    }
                case .tokenRefreshed, .userUpdated:
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
    private func applySupabaseSession(_ session: Session, pullProfile: Bool = false) {
        var account = PlottyAccountMapper.makeAccount(from: session.user)
        if let override = displayNameOverrides[account.id.uuidString] {
            account.displayName = override
        }
        storedAccount = account
        lastUsedProvider = account.provider
        persistPreferences()
        if pullProfile {
            Task { await onProfileSyncNeeded?() }
        }
    }

    @MainActor
    private func performLogout(isOnline: Bool) async -> Result<Void, AuthError> {
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: "logout", error: .offline, provider: storedAccount?.provider)
            return .failure(.offline)
        }
        if supabaseEnabled {
            do {
                try await AuthService.signOut()
            } catch {
                PlotAnalytics.trackAuthFailure(action: "logout", error: .logoutFailed, provider: storedAccount?.provider)
                return .failure(.logoutFailed)
            }
        }
        let provider = storedAccount?.provider ?? .email
        clearLocalSession()
        PlotAnalytics.trackAuthSuccess(action: "logout", provider: provider)
        return .success(())
    }

    @MainActor
    private func performDeleteAccount(isOnline: Bool) async -> Result<Void, AuthError> {
        guard isOnline else {
            PlotAnalytics.trackAuthFailure(action: "delete_account", error: .offline, provider: storedAccount?.provider)
            return .failure(.offline)
        }
        guard supabaseEnabled else {
            let provider = storedAccount?.provider ?? .email
            clearLocalSession()
            PlotAnalytics.trackAuthSuccess(action: "delete_account", provider: provider)
            return .success(())
        }

        do {
            try await AuthService.deleteCurrentUserData()
            try await AuthService.signOut()
            let provider = storedAccount?.provider ?? .email
            clearLocalSession()
            PlotAnalytics.trackAuthSuccess(action: "delete_account", provider: provider)
            return .success(())
        } catch {
            PlotAnalytics.trackAuthFailure(action: "delete_account", error: .deleteAccountFailed, provider: storedAccount?.provider)
            return .failure(.deleteAccountFailed)
        }
    }

    @MainActor
    private func clearLocalSession() {
        storedAccount = nil
        persistPreferences()
    }

    // MARK: - モック（プレビュー用）

    @MainActor
    private func performSupabaseOAuthLogin(
        provider: AuthProvider,
        email: String?,
        pullProfile: Bool = true
    ) async -> Result<Void, AuthError> {
        guard supabaseEnabled else {
            loginWithMock(provider: provider, email: email)
            return .success(())
        }
        do {
            let session = try await AuthService.signInWithGoogle()
            applySupabaseSession(session, pullProfile: pullProfile)
            PlotAnalytics.trackAuthSuccess(action: "login", provider: provider)
            return .success(())
        } catch {
            PlotAnalytics.trackAuthFailure(action: "login", error: .providerUnavailable(provider.title), provider: provider)
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
    private func syncSignUpProfile(displayNameOverride: String?) async {
        let timezoneIdentifier = TimeZone.current.identifier
        let name = (displayNameOverride ?? storedAccount?.displayName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if name.isEmpty {
                try await UserProfileService.updateProfile(timezoneIdentifier: timezoneIdentifier)
            } else {
                try await UserProfileService.updateProfile(
                    displayName: name,
                    timezoneIdentifier: timezoneIdentifier
                )
            }
        } catch {
            // 新規登録直後の初期同期はベストエフォート
        }
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
