import Foundation
import Supabase

/// Plotty が利用する認証エントリ（Google OAuth / Sign in with Apple / Email OTP など）。
enum AuthService {
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

    /// メールに OTP / マジックリンクを送信する。
    @MainActor
    static func sendEmailOTP(
        email: String,
        createUser: Bool,
        data: [String: AnyJSON]? = nil
    ) async throws {
        try await SupabaseManager.client.auth.signInWithOTP(
            email: email,
            redirectTo: PlottyAuthRedirect.callbackURL,
            shouldCreateUser: createUser,
            data: data
        )
    }

    /// メール OTP を検証してセッションを確立する。
    @MainActor
    static func verifyEmailOTP(
        email: String,
        token: String,
        type: EmailOTPType
    ) async throws -> Session {
        let response = try await SupabaseManager.client.auth.verifyOTP(
            email: email,
            token: token,
            type: type,
            redirectTo: PlottyAuthRedirect.callbackURL
        )
        switch response {
        case .session(let session):
            return session
        case .user:
            return try await SupabaseManager.client.auth.session
        }
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
