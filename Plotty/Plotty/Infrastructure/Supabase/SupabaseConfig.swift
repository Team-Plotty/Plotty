import Foundation

/// Bundled `SupabaseSecrets.plist`（gitignore の実ファイル側）からURLと匿名キーを読む。
enum SupabaseConfig {
    struct Values {
        let supabaseURL: URL
        let anonKey: String
    }

    enum LoadError: Error {
        /// プラセホルダのまま、または plist が無い／キー欠落。
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
        return Values(supabaseURL: supabaseURL, anonKey: anonKey)
    }
}
