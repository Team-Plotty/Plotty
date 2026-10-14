import SwiftUI

// MARK: - 一覧タブの特定データを開く指示
/// チャットの登録カードから、該当タブへ切り替えて編集シートを開くために使う。
/// `ContentView` が保持し、対象タブが受け取って編集シートを開いたら `nil` に戻す。
struct PlotEntityRoute: Equatable {
    let category: PlotChatCategory
    let id: UUID
    
    var tab: TabItem {
        switch category {
        case .memo: return .memo
        case .task: return .todo
        case .schedule: return .calendar
        }
    }
}

extension View {
    /// `route` が自分のカテゴリを指したら、該当データを探して `open` を呼ぶ。
    /// チャットで登録した直後や別端末で作成したデータは一覧に未反映のことがあるため、見つからなければ 1 回だけ再読み込みする。
    func plotOpensEntityRoute<Item>(
        _ route: Binding<PlotEntityRoute?>,
        category: PlotChatCategory,
        find: @escaping (UUID) -> Item?,
        reload: @escaping () async -> Void,
        open: @escaping (Item) -> Void
    ) -> some View {
        modifier(
            PlotEntityRouteOpener(
                route: route,
                category: category,
                find: find,
                reload: reload,
                open: open
            )
        )
    }
}

private struct PlotEntityRouteOpener<Item>: ViewModifier {
    @Binding var route: PlotEntityRoute?
    let category: PlotChatCategory
    let find: (UUID) -> Item?
    let reload: () async -> Void
    let open: (Item) -> Void
    
    @State private var notFoundMessage: String?
    
    func body(content: Content) -> some View {
        content
            // タブが表示された時点と、表示中に新しい指示が来た時点の両方で拾う
            .task(id: route) { await openIfNeeded() }
            .plotErrorAlert("開けませんでした", message: $notFoundMessage)
    }
    
    @MainActor
    private func openIfNeeded() async {
        guard let target = route, target.category == category else { return }
        var item = find(target.id)
        if item == nil {
            await reload()
            item = find(target.id)
        }
        route = nil
        if let item {
            open(item)
        } else {
            notFoundMessage = "このデータは削除されたか、見つかりませんでした。"
        }
    }
}
