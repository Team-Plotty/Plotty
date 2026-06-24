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
struct PlotAppleSignInButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: SignInWithAppleButton.Label
    let isDisabled: Bool
    let onComplete: (Result<AppleSignInPayload, Error>) -> Void

    @State private var rawNonce = ""

    var body: some View {
        SignInWithAppleButton(label) { request in
            let nonce = PlotAppleSignInNonce.random()
            rawNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = PlotAppleSignInNonce.sha256(nonce)
        } onCompletion: { result in
            Task { @MainActor in
                await handleCompletion(result)
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }

    @MainActor
    private func handleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            onComplete(.failure(error))
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                onComplete(.failure(AppleSignInError.unexpectedCredential))
                return
            }
            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                onComplete(.failure(AppleSignInError.missingIdentityToken))
                return
            }
            guard !rawNonce.isEmpty else {
                onComplete(.failure(AppleSignInError.missingNonce))
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
    case missingNonce
    case unexpectedCredential

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken, .missingNonce, .unexpectedCredential:
            return "Appleでのログインに失敗しました。しばらくしてから再試行してください。"
        }
    }
}
