import Foundation

/// OAuth 完了後にアプリへ戻る URL。Scheme は Info.plist の URL Types と一致させること。
enum PlottyAuthRedirect {
    static let scheme = "plotty"

    /// Supabase Dashboard の Redirect URLs に `plotty://auth-callback` を登録する。
    static let callbackURL = URL(string: "\(scheme)://auth-callback")!
}
