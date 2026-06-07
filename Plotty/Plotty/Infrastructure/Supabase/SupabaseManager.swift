import Foundation
import Supabase

/// Supabase クライアントの初期化・共有アクセス。
enum SupabaseManager {
    private static let secrets: SupabaseConfig.Values = {
        do {
            return try SupabaseConfig.load()
        } catch {
            preconditionFailure(
                "SupabaseSecrets.plist を用意し SUPABASE_URL / SUPABASE_ANON_KEY を設定してください。"
            )
        }
    }()

    /// `SupabaseSecrets.plist` を Copy Bundle Resources に含め、値を設定してから参照する。
    static let client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: secrets.supabaseURL,
            supabaseKey: secrets.anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: PlottyAuthRedirect.callbackURL
                )
            )
        )
    }()

    /// Plotty Edge API の Base URL（`.../functions/v1/plotty-api`）。Phase C の `PlotAPIClient` が使用する。
    static var edgeAPIBaseURL: URL { secrets.edgeAPIBaseURL }

    /// OAuth コールバック URL を Supabase Auth に渡す。
    static func handleOpenURL(_ url: URL) {
        client.handle(url)
    }
}
