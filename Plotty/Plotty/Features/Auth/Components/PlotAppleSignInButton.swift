// [SNS認証停止] 認証はメールのみで運用するため Sign in with Apple は無効化中（ファイル全体をコメントアウト）
/*
import AuthenticationServices
import Supabase
import SwiftUI

/// Sign in with Apple の完了ペイロード。
struct AppleSignInPayload: Sendable {
    let session: Session
    /// Apple が初回のみ返す氏名（2 回目以降は `nil`）。
    let suggestedDisplayName: String?
}

/// Sign in with Apple（Supabase `signInWithIdToken` へ接続）。
/// システム標準の `SignInWithAppleButton` はフォントや余白を変えられず Google ボタンと揃わないため、
/// 共通スタイルの自前ボタンから `authorizationController` で認証を起動する。
struct PlotAppleSignInButton: View {
    enum Purpose {
        case signIn
        case signUp

        var title: String {
            switch self {
            case .signIn: return "Appleでログイン"
            case .signUp: return "Appleで登録"
            }
        }
    }

    @Environment(\.authorizationController) private var authorizationController

    let purpose: Purpose
    let isDisabled: Bool
    var isRecommended: Bool = false
    let onComplete: (Result<AppleSignInPayload, Error>) -> Void

    var body: some View {
        Button {
            Task { await signIn() }
        } label: {
            PlotSocialSignInLabel(title: purpose.title, icon: Image(systemName: "apple.logo"))
        }
        .buttonStyle(PlotSocialSignInButtonStyle(isRecommended: isRecommended))
        .disabled(isDisabled)
    }

    @MainActor
    private func signIn() async {
        let rawNonce = PlotAppleSignInNonce.random()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = PlotAppleSignInNonce.sha256(rawNonce)

        let result: ASAuthorizationResult
        do {
            result = try await authorizationController.performRequest(request)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            return
        } catch {
            onComplete(.failure(error))
            return
        }

        guard case .appleID(let credential) = result else {
            onComplete(.failure(AppleSignInError.unexpectedCredential))
            return
        }
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            onComplete(.failure(AppleSignInError.missingIdentityToken))
            return
        }
        do {
            let session = try await AuthService.signInWithApple(idToken: idToken, nonce: rawNonce)
            let suggestedName = suggestedDisplayName(from: credential)
            onComplete(.success(AppleSignInPayload(session: session, suggestedDisplayName: suggestedName)))
        } catch {
            onComplete(.failure(error))
        }
    }

    private func suggestedDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String? {
        guard let components = credential.fullName else { return nil }
        let formatted = PersonNameComponentsFormatter()
            .string(from: components)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return formatted.isEmpty ? nil : formatted
    }
}

enum AppleSignInError: LocalizedError {
    case missingIdentityToken
    case unexpectedCredential

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken, .unexpectedCredential:
            return "Appleでのログインに失敗しました。しばらくしてから再試行してください。"
        }
    }
}
*/
