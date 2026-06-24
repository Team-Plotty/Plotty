import Foundation
import Supabase

// MARK: - JWT 供給（テスト差し替え用）

protocol PlotAPIAccessTokenProviding: Sendable {
    func accessToken() async throws -> String
}

/// Supabase Auth セッションから access token を取得する。
struct SupabasePlotAPIAccessTokenProvider: PlotAPIAccessTokenProviding {
    func accessToken() async throws -> String {
        let session = try await SupabaseManager.client.auth.session
        let token = session.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            throw PlotAPIError.missingAccessToken
        }
        return token
    }
}
