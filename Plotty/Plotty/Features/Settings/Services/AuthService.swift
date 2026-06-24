import Foundation
import Supabase

/// Plotty が利用する認証エントリ（Google OAuth など）。
enum AuthService {
    /// Google アカウントで Supabase にサインインする（ブラウザセッションを表示）。
    @MainActor
    static func signInWithGoogle() async throws -> Session {
        try await SupabaseManager.client.auth.signInWithOAuth(provider: .google)
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
