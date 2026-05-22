import SwiftUI

// MARK: - チャット送信カテゴリ（schedule / task / memo）
enum PlotChatCategory: String, CaseIterable, Identifiable {
    case schedule
    case task
    case memo
    
    var id: String { rawValue }
    
    /// 登録確認カードのカテゴリ変更ボタン（左からメモ → ToDo → カレンダー）
    static let reclassifyButtonOrder: [PlotChatCategory] = [.memo, .task, .schedule]
    
    /// キーボードのクイックアクション（上からカレンダー → ToDo → メモ）
    static let quickActionOrder: [PlotChatCategory] = [.schedule, .task, .memo]
    
    var label: String {
        switch self {
        case .schedule: return "カレンダー"
        case .task: return "ToDo"
        case .memo: return "メモ"
        }
    }
    
    /// キーボード表示時のクイックアクション行ラベル
    var quickActionTitle: String {
        switch self {
        case .schedule: return "カレンダー"
        case .task: return "ToDo"
        case .memo: return "メモ"
        }
    }
    
    var icon: String {
        switch self {
        case .schedule: return "calendar"
        case .task: return "checklist"
        case .memo: return "doc.text"
        }
    }
    
    var detail: String {
        switch self {
        case .schedule: return "カレンダーに登録"
        case .task: return "ToDo に登録"
        case .memo: return "メモに保存"
        }
    }
    
    /// 入力欄内チップの tint（ダーク）
    var chipTintDark: Color {
        switch self {
        case .schedule: return Color(hex: "#6EB5FF")
        case .task: return Color(hex: "#8FD99A")
        case .memo: return Color(hex: "#C4B8A8")
        }
    }
    
    /// 入力欄内チップの tint（ライト）
    var chipTintLight: Color {
        switch self {
        case .schedule: return Color(hex: "#2563EB")
        case .task: return Color(hex: "#15803D")
        case .memo: return Color(hex: "#57534E")
        }
    }
}
