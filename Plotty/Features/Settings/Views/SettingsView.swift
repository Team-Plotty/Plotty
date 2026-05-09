import SwiftUI

struct SettingsView: View {
    @State private var googleSignInMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
            Button("Googleでログイン") {
                googleSignInMessage = nil
                Task { @MainActor in
                    do {
                        try await AuthService.signInWithGoogle()
                        googleSignInMessage = "ログインに成功しました"
                    } catch {
                        googleSignInMessage = error.localizedDescription
                    }
                }
            }
            if let googleSignInMessage {
                Text(googleSignInMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
