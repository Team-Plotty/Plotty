import SwiftUI

// MARK: - 最前面の画面を閉じる操作（Environment）
/// `PlotCrossDissolveStack` で重ねた画面から、自分自身を閉じるための操作。`@Environment(\.dismiss)` の代わりに使う。
struct PlotCrossDissolveDismissAction {
    fileprivate let action: () -> Void

    func callAsFunction() {
        action()
    }
}

private struct PlotCrossDissolveDismissKey: EnvironmentKey {
    static let defaultValue = PlotCrossDissolveDismissAction(action: {})
}

extension EnvironmentValues {
    var plotCrossDissolveDismiss: PlotCrossDissolveDismissAction {
        get { self[PlotCrossDissolveDismissKey.self] }
        set { self[PlotCrossDissolveDismissKey.self] = newValue }
    }
}

// MARK: - クロスディゾルブで画面を積むナビゲーション
/// `NavigationStack` のプッシュ（横スライド）は SwiftUI だけでは差し替えられないため、
/// ルート画面の上に経路の画面を重ね、透過の入れ替えで遷移させる。
/// 各画面は不透明な背景を持つ前提で、上の層のフェードだけで前後の画面が入れ替わって見える。
/// 下の層は破棄しないので、戻ったときに入力中の内容が残る。
struct PlotCrossDissolveStack<Route: Hashable, Root: View, Destination: View>: View {
    @Binding var path: [Route]
    @ViewBuilder var root: () -> Root
    @ViewBuilder var destination: (Route) -> Destination

    var body: some View {
        ZStack {
            NavigationStack {
                root()
            }
            .allowsHitTesting(path.isEmpty)
            .accessibilityHidden(!path.isEmpty)

            ForEach(Array(path.enumerated()), id: \.offset) { index, route in
                let isTop = index == path.count - 1

                // タイトルやツールバーが他の層と混ざらないよう、層ごとに NavigationStack を持たせる
                NavigationStack {
                    destination(route)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    pop(from: index)
                                } label: {
                                    Image(systemName: "chevron.backward")
                                }
                                .accessibilityLabel("戻る")
                            }
                        }
                }
                .environment(\.plotCrossDissolveDismiss, PlotCrossDissolveDismissAction { pop(from: index) })
                .allowsHitTesting(isTop)
                .accessibilityHidden(!isTop)
                // 閉じるときのフェード中も下の層より前に描画し続けるため
                .zIndex(Double(index + 1))
                .transition(.opacity)
            }
        }
        .animation(.crossDissolve, value: path)
    }

    /// `index` の層とそれより上の層をまとめて閉じる。
    private func pop(from index: Int) {
        guard path.indices.contains(index) else { return }
        path.removeSubrange(index...)
    }
}
