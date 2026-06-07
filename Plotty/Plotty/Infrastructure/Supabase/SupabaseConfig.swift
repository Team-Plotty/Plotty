import Foundation

/// Bundled `SupabaseSecrets.plist`（gitignore の実ファイル側）から URL と匿名キーを読む。
enum SupabaseConfig {
    /// Supabase Edge Functions 上の API 関数名（A4 deploy 名と一致）
    static let edgeFunctionName = "plotty-api"

    struct Values {
        let supabaseURL: URL
        let anonKey: String
        /// `https://<ref>.supabase.co/functions/v1/plotty-api`（または plist 上書き）
        let edgeAPIBaseURL: URL

        /// 例: `api/v1/entities` → `.../plotty-api/api/v1/entities`
        func edgeAPIURL(relativePath: String) -> URL {
            let trimmed = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return edgeAPIBaseURL.appending(path: trimmed)
        }
    }

    enum LoadError: Error {
        /// プレースホルダのまま、または plist が無い／キー欠落。
        case missingOrInvalidSecrets
    }

    private static let placeholderSentinel = "REPLACE_ME"

    static func load() throws -> Values {
        guard let plistURL = Bundle.main.url(forResource: "SupabaseSecrets", withExtension: "plist"),
              let data = try? Data(contentsOf: plistURL),
              let raw = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = raw as? [String: Any],
              let urlString = dict["SUPABASE_URL"] as? String,
              let anonKey = dict["SUPABASE_ANON_KEY"] as? String,
              urlString != placeholderSentinel,
              anonKey != placeholderSentinel,
              urlString.starts(with: "http"),
              let supabaseURL = URL(string: urlString)
        else {
            throw LoadError.missingOrInvalidSecrets
        }

        let edgeAPIBaseURL = resolveEdgeAPIBaseURL(from: dict, supabaseURL: supabaseURL)
        return Values(supabaseURL: supabaseURL, anonKey: anonKey, edgeAPIBaseURL: edgeAPIBaseURL)
    }

    private static func resolveEdgeAPIBaseURL(from dict: [String: Any], supabaseURL: URL) -> URL {
        if let override = dict["PLOT_API_BASE_URL"] as? String,
           override != placeholderSentinel,
           override.starts(with: "http"),
           let url = URL(string: override) {
            return url
        }
        return makeEdgeAPIBaseURL(from: supabaseURL)
    }

    private static func makeEdgeAPIBaseURL(from supabaseURL: URL) -> URL {
        let root = supabaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(root)/functions/v1/\(edgeFunctionName)") else {
            preconditionFailure("Edge API Base URL を生成できません: \(supabaseURL.absoluteString)")
        }
        return url
    }
}
