import Foundation
import Supabase

/// Plotty が利用する認証エントリ（Google OAuth など）。
enum AuthService {
    /// Google アカウントで Supabase にサインインする（ブラウザセッションを表示）。
    @MainActor
    static func signInWithGoogle() async throws {
        _ = try await SupabaseManager.client.auth.signInWithOAuth(provider: .google)
    }
}
