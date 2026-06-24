import Foundation

// MARK: - 本実装時削除（開発・切り分け用フラグ）
enum PlotDebug {
    /// `true` のとき `ContentView` の代わりに TextField だけの画面を出す（キーボード切り分け）
    static let keyboardProbeOnly = false
    
    /// `true` のとき起動時にログイン画面を表示（本番相当）
    static let requireLoginOnLaunch = true
    
    /// デモ用: ログインをスキップしてチャットタブから起動（本実装時削除）
    static let demoLaunchToChat = false
    
    /// `true` のとき一覧の再読み込みを意図的に失敗させる（UI 確認用）
    static let simulateDataLoadFailure = false
    
    /// `true` のときチャット応答を常に 10 秒タイムアウト扱いにする
    static let forceChatTimeout = false
}
