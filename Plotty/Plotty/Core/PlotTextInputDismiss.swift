import SwiftUI

// MARK: - テキスト入力のフォーカス解除（アプリ共通）
// 仕組み:
// 1. ルートに `plotDismissTextInputOnTapOutside()` を 1 回だけ付け、画面のどこをタップしても拾う
// 2. 入力欄側は `plotTextInputArea()` で「タップしても閉じない領域」を登録する
// 3. 登録領域の外をタップしたら通知し、各画面は `plotDismissTextInputOnNotification` で自分のフォーカスを外す
// 画面ごとに「ここをタップしたら閉じる」を付けて回る方式だと、付け忘れた領域（ヘッダー・空白など）で閉じられないため。
// UIKit の resignFirstResponder は使わない方針のため、フォーカスは各画面の `@FocusState` で外す。

extension Notification.Name {
    /// 入力欄外のタップやタブ切替など、入力を終えるべき操作で投稿
    static let plotDismissTextInput = Notification.Name("plotDismissTextInput")
}

extension View {
    /// アプリのルートに 1 回だけ付ける。`plotTextInputArea()` の外をタップしたらフォーカス解除を通知する。
    /// シートは別階層のため対象外（シート内の入力はそれぞれのフォームのスクロール等で閉じる）
    func plotDismissTextInputOnTapOutside() -> some View {
        modifier(PlotDismissTextInputOnTapOutsideModifier())
    }
    
    /// タップしてもキーボードを閉じない領域として登録する（入力欄そのもの・送信ボタン・入力中に使うカテゴリ選択など）
    func plotTextInputArea() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PlotTextInputAreaPreferenceKey.self,
                    value: [proxy.frame(in: .global)]
                )
            }
        }
    }
    
    /// `plotDismissTextInput` 通知でフォーカスを外す
    func plotDismissTextInputOnNotification(
        isFocused: FocusState<Bool>.Binding
    ) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .plotDismissTextInput)) { _ in
            isFocused.wrappedValue = false
        }
    }
    
    /// 複数の入力欄を 1 つの `@FocusState`（enum）で管理する画面向け
    func plotDismissTextInputOnNotification<Field: Hashable>(
        focusedField: FocusState<Field?>.Binding
    ) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .plotDismissTextInput)) { _ in
            focusedField.wrappedValue = nil
        }
    }
}

/// 画面上の入力欄の位置（グローバル座標）
private struct PlotTextInputAreaPreferenceKey: PreferenceKey {
    static let defaultValue: [CGRect] = []
    
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

private struct PlotDismissTextInputOnTapOutsideModifier: ViewModifier {
    @State private var inputAreas: [CGRect] = []
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(PlotTextInputAreaPreferenceKey.self) { areas in
                inputAreas = areas
            }
            // 子のボタンやスクロールを妨げないよう、同時認識のタップで拾う
            .simultaneousGesture(
                SpatialTapGesture(coordinateSpace: .global).onEnded { value in
                    guard !inputAreas.contains(where: { $0.contains(value.location) }) else { return }
                    PlotTextInputDismiss.postNotification()
                }
            )
    }
}

enum PlotTextInputDismiss {
    static func postNotification() {
        NotificationCenter.default.post(name: .plotDismissTextInput, object: nil)
    }
}
