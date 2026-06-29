import Foundation

// MARK: - 開発ビルド専用フラグ（Release ではコンパイルされない）
#if DEBUG
enum PlotDebug {
    /// `true` のとき `ContentView` の代わりに TextField だけの画面を出す（キーボード切り分け）
    static let keyboardProbeOnly = false

    /// デモ用: ログインをスキップしてチャットタブから起動
    static let demoLaunchToChat = false

    /// `true` のとき一覧の再読み込みを意図的に失敗させる（UI 確認用）
    static let simulateDataLoadFailure = false

    /// `true` のときチャット応答を常に 10 秒タイムアウト扱いにする
    static let forceChatTimeout = false
}
#endif
