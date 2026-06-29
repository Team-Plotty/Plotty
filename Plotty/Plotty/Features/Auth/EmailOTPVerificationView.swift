import SwiftUI

// MARK: - メール OTP 入力（ログイン / 新規登録共通）
struct EmailOTPVerificationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accountSession) private var accountSession
    @Environment(\.connectivity) private var connectivity

    let challenge: EmailOTPChallenge
    let onSuccess: () -> Void

    @State private var otpCode = ""
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var resendCooldown = 0
    @FocusState private var isOTPFocused: Bool

    private let otpLength = 6
    private let resendInterval = 60

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header

                    if !connectivity.isOnline {
                        PlotOfflineBanner()
                    }

                    if let infoMessage {
                        PlotInfoBanner(message: infoMessage)
                    }

                    if let errorMessage {
                        PlotErrorBanner(message: errorMessage, onRetry: nil)
                    }

                    otpField
                    verifyButton
                    resendSection
                    magicLinkNote
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.vertical, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(challenge.purpose.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("戻る") { dismiss() }
            }
        }
        .onAppear {
            infoMessage = "\(challenge.email) に認証コードを送信しました。"
            isOTPFocused = true
        }
        .overlay {
            if isVerifying {
                PlotLoadingOverlay(message: "確認しています…")
            } else if isResending {
                PlotLoadingOverlay(message: "再送しています…")
            }
        }
        .task(id: resendCooldown) {
            guard resendCooldown > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            if resendCooldown > 0 {
                resendCooldown -= 1
            }
        }
        .plotAnalyticsScreen(.emailOTP)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("認証コードを入力")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(primaryColor)

            Text("メールに届いた \(otpLength) 桁のコードを入力してください。リンクが届いた場合は、そのリンクをタップしてもログインできます。")
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryColor)
        }
    }

    private var otpField: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("認証コード")
                .font(.scaledCaption())
                .foregroundStyle(secondaryColor)

            TextField("000000", text: $otpCode)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundStyle(primaryColor)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .focused($isOTPFocused)
                .onChange(of: otpCode) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    otpCode = String(digits.prefix(otpLength))
                    if otpCode.count == otpLength {
                        verifyCode()
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(minHeight: 56)
                .background {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Color.clear)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                }
        }
    }

    private var verifyButton: some View {
        Button(action: verifyCode) {
            Text(challenge.purpose == .signup ? "登録を完了" : "ログインする")
                .font(.scaledBodyLarge().weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .disabled(!canVerify || isVerifying || isResending)
        .buttonStyle(EmailOTPAcceptButtonStyle(isEnabled: canVerify && !isVerifying && !isResending))
    }

    private var resendSection: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: resendCode) {
                if resendCooldown > 0 {
                    Text("認証コードを再送（\(resendCooldown)秒）")
                } else {
                    Text("認証コードを再送")
                }
            }
            .font(.scaledBodyMedium().weight(.semibold))
            .foregroundStyle(resendCooldown > 0 ? secondaryColor : Color.accentColor)
            .disabled(resendCooldown > 0 || isVerifying || isResending || !connectivity.isOnline)
        }
        .frame(maxWidth: .infinity)
    }

    private var magicLinkNote: some View {
        Text("メール内のリンクから開いた場合は、この画面を閉じて自動的にログインされます。")
            .font(.scaledCaption())
            .foregroundStyle(secondaryColor)
            .frame(maxWidth: .infinity)
    }

    private var canVerify: Bool {
        otpCode.count == otpLength
    }

    private func verifyCode() {
        guard canVerify else { return }
        errorMessage = nil
        isOTPFocused = false
        isVerifying = true

        Task {
            let result = await accountSession.verifyEmailOTP(
                email: challenge.email,
                code: otpCode,
                purpose: challenge.purpose,
                displayName: challenge.displayName,
                isOnline: connectivity.isOnline
            )
            await MainActor.run {
                isVerifying = false
                switch result {
                case .success:
                    onSuccess()
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    isOTPFocused = true
                }
            }
        }
    }

    private func resendCode() {
        guard resendCooldown == 0 else { return }
        errorMessage = nil
        infoMessage = nil
        isResending = true

        Task {
            let result = await accountSession.sendEmailOTP(
                email: challenge.email,
                purpose: challenge.purpose,
                displayName: challenge.displayName,
                isOnline: connectivity.isOnline
            )
            await MainActor.run {
                isResending = false
                switch result {
                case .success:
                    infoMessage = "\(challenge.email) に認証コードを再送しました。"
                    resendCooldown = resendInterval
                    otpCode = ""
                    isOTPFocused = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryColor: Color {
        colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5)
    }
}

// MARK: - 補助 UI

private struct PlotInfoBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "envelope.badge")
                .foregroundStyle(Color.accentColor)
            Text(message)
                .font(.scaledBodySmall())
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

private struct EmailOTPAcceptButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isEnabled ? Color.accentColor : Color.gray.opacity(0.5))
            }
            .glassEffect(isEnabled ? .regular.interactive() : .regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EmailOTPVerificationView(
            challenge: EmailOTPChallenge(email: "preview@plotty.app", purpose: .login),
            onSuccess: {}
        )
        .environment(\.accountSession, AccountSession.preview(loggedIn: false))
        .environment(\.connectivity, ConnectivityMonitor())
    }
}
#endif
