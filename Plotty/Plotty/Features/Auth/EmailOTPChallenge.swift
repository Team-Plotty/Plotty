import Foundation

/// 認証コード入力画面へ渡す情報。
/// 認証コードはパスワードを忘れたときのログイン専用（新規登録はメール＋パスワードに一本化）。
struct EmailOTPChallenge: Identifiable, Hashable, Sendable {
    let email: String

    var id: String { email.lowercased() }
}
