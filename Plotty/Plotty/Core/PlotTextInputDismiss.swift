import SwiftUI

// MARK: - テキスト入力のフォーカス解除（検索・チャット共通）
extension Notification.Name {
    /// タブバー・FAB・パンくずなど、入力欄外の UI 操作時に投稿
    static let plotDismissTextInput = Notification.Name("plotDismissTextInput")
}

extension View {
    /// この領域をタップしたらフォーカスを外す（検索欄・入力ドック自体には付けない）
    func plotDismissTextInputWhenTappingOutside(
        isFocused: FocusState<Bool>.Binding
    ) -> some View {
        modifier(PlotDismissTextInputOnTapOutsideModifier(isFocused: isFocused))
    }
    
    /// `plotDismissTextInput` 通知でフォーカスを外す
    func plotDismissTextInputOnNotification(
        isFocused: FocusState<Bool>.Binding
    ) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .plotDismissTextInput)) { _ in
            isFocused.wrappedValue = false
        }
    }
}

private struct PlotDismissTextInputOnTapOutsideModifier: ViewModifier {
    let isFocused: FocusState<Bool>.Binding
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    guard isFocused.wrappedValue else { return }
                    isFocused.wrappedValue = false
                }
            )
    }
}

enum PlotTextInputDismiss {
    static func postNotification() {
        NotificationCenter.default.post(name: .plotDismissTextInput, object: nil)
    }
}
