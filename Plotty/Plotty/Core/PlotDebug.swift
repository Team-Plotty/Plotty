import Foundation

// MARK: - 一時的な切り分け用フラグ（調査が終わったら `false` に戻す）
enum PlotDebug {
    /// `true` のとき `ContentView` の代わりに TextField だけの画面を出す（キーボード切り分け）
    static let keyboardProbeOnly = false
    
    /// `true` のとき起動時にログイン画面を表示（本番相当）
    static let requireLoginOnLaunch = true
    
    /// `true` のとき一覧の再読み込みを意図的に失敗させる（UI 確認用）
    static let simulateDataLoadFailure = false
    
    /// `true` のときチャット応答を常に 10 秒タイムアウト扱いにする
    static let forceChatTimeout = false
}
