import Foundation
import Supabase

/// Plotty が利用する認証エントリ（メール＋パスワード / Google OAuth / Sign in with Apple / Email OTP）。
enum AuthService {
    /// メールアドレスとパスワードでアカウントを作成する。
    /// メール確認をオフにしている前提なので、成功時はそのままセッションが返る。
    /// 確認がオンのままだとセッションが付かないため `nil` を返す（呼び出し側でエラー扱い）。
    @MainActor
    static func signUpWithPassword(email: String, password: String) async throws -> Session? {
        try await SupabaseManager.client.auth.signUp(email: email, password: password).session
    }

    /// メールアドレスとパスワードでサインインする。
    @MainActor
    static func signInWithPassword(email: String, password: String) async throws -> Session {
        try await SupabaseManager.client.auth.signIn(email: email, password: password)
    }

    /// ログイン中ユーザーのパスワードを設定・変更する。
    @MainActor
    static func updatePassword(_ password: String) async throws {
        _ = try await SupabaseManager.client.auth.update(user: UserAttributes(password: password))
    }

    /// Google アカウントで Supabase にサインインする（ブラウザセッションを表示）。
    @MainActor
    static func signInWithGoogle() async throws -> Session {
        try await SupabaseManager.client.auth.signInWithOAuth(provider: .google)
    }

    /// Sign in with Apple の ID トークンで Supabase にサインインする。
    @MainActor
    static func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        try await SupabaseManager.client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    /// 既存アカウントのメールに OTP / マジックリンクを送信する（パスワードを忘れたときのログイン用）。
    /// 新規作成はパスワード登録に一本化したため、ここではアカウントを作らない。
    @MainActor
    static func sendEmailOTP(email: String) async throws {
        try await SupabaseManager.client.auth.signInWithOTP(
            email: email,
            redirectTo: PlottyAuthRedirect.callbackURL,
            shouldCreateUser: false
        )
    }

    /// メール OTP を検証してセッションを確立する。
    @MainActor
    static func verifyEmailOTP(email: String, token: String) async throws -> Session {
        let response = try await SupabaseManager.client.auth.verifyOTP(
            email: email,
            token: token,
            type: .email,
            redirectTo: PlottyAuthRedirect.callbackURL
        )
        switch response {
        case .session(let session):
            return session
        case .user:
            return try await SupabaseManager.client.auth.session
        }
    }

    /// `public.users.timezone` を更新する（新規登録直後の初期同期用）。
    @MainActor
    static func updateCurrentUserTimezone(_ timezoneIdentifier: String) async throws {
        try await UserProfileService.updateProfile(timezoneIdentifier: timezoneIdentifier)
    }

    /// 現在ユーザーの `public.users` 行を削除する（配下データは FK CASCADE で削除）。
    @MainActor
    static func deleteCurrentUserData() async throws {
        let session = try await SupabaseManager.client.auth.session
        try await SupabaseManager.client
            .from("users")
            .delete()
            .eq("id", value: session.user.id)
            .execute()
    }

    /// Supabase セッションを終了する。
    @MainActor
    static func signOut() async throws {
        try await SupabaseManager.client.auth.signOut()
    }

    /// 永続化済みの Supabase セッションを取得する（未ログイン時は `nil`）。
    @MainActor
    static func restoredSession() async -> Session? {
        try? await SupabaseManager.client.auth.session
    }
}
