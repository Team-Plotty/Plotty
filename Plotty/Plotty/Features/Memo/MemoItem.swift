import Foundation

// MARK: - メモのデータモデル
struct MemoItem: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var updatedAt: Date
    var isPinned: Bool = false
    var accent: AccentSwatch = .graphite
}

// MARK: - 本実装時削除（開発用サンプルデータ）
extension MemoItem {
    static var sampleData: [MemoItem] {
        [
            MemoItem(title: "買い物リスト", content: "牛乳、卵、パン、野菜", updatedAt: Date(), isPinned: true, accent: .sage),
            MemoItem(title: "アイデアメモ", content: "新機能のアイデア：音声入力対応、カレンダー連携の強化", updatedAt: Date().addingTimeInterval(-3600), accent: .sky),
            MemoItem(title: "読書メモ", content: "第3章のポイント：習慣化には環境が重要", updatedAt: Date().addingTimeInterval(-86400), accent: .coral),
            MemoItem(title: "リンク集", content: "", updatedAt: Date().addingTimeInterval(-7200), accent: .graphite),
            MemoItem(title: "下書き", content: "ペーパートーン試し", updatedAt: Date().addingTimeInterval(-4000), accent: .paper),
        ]
    }
}
