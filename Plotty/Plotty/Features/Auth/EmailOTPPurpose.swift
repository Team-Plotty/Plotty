import Foundation
import Supabase

/// メール OTP の用途（Supabase `EmailOTPType` に対応）。
enum EmailOTPPurpose: String, Hashable, Sendable {
    case login
    case signup

    var createsUser: Bool {
        switch self {
        case .login: return false
        case .signup: return true
        }
    }

    var verificationType: EmailOTPType {
        switch self {
        case .login: return .email
        case .signup: return .signup
        }
    }

    var sendButtonTitle: String {
        switch self {
        case .login: return "認証コードを送信"
        case .signup: return "認証コードを送信"
        }
    }

    var navigationTitle: String {
        switch self {
        case .login: return "メールでログイン"
        case .signup: return "メールで登録"
        }
    }
}

/// メール OTP 入力画面へ渡すチャレンジ情報。
struct EmailOTPChallenge: Identifiable, Hashable, Sendable {
    let email: String
    let purpose: EmailOTPPurpose
    var displayName: String?

    var id: String { "\(purpose.rawValue)-\(email.lowercased())" }
}
