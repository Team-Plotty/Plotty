import SwiftUI

// MARK: - エラー表示（アラート）
/// エラー（オフラインを含む）はアラートで出す。
/// 画面内にバナーを差し込むと入力欄やリストの位置がずれ、操作中の内容を見失わせるため。
private struct PlotErrorAlertModifier: ViewModifier {
    @Environment(\.plotTabIsActive) private var isActiveTab

    let title: String
    @Binding var message: String?
    let onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content.alert(
            title,
            isPresented: Binding(
                // 裏のタブのエラーは、そのタブが前面に来たときに出す
                get: { isActiveTab && message != nil },
                set: { isPresented in
                    if !isPresented { message = nil }
                }
            )
        ) {
            if let onRetry {
                Button("閉じる", role: .cancel) {}
                Button("再試行") {
                    // 閉じる処理（message を nil に戻す）の後に実行し、再試行ですぐ出た新しいエラーを消さないようにする
                    Task { @MainActor in onRetry() }
                }
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(message ?? "")
        }
    }
}

extension View {
    /// - Parameters:
    ///   - message: `nil` 以外でアラートを出し、閉じると `nil` に戻す。
    ///   - onRetry: 渡したときだけ「再試行」ボタンを出す。
    func plotErrorAlert(
        _ title: String,
        message: Binding<String?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(PlotErrorAlertModifier(title: title, message: message, onRetry: onRetry))
    }
}
