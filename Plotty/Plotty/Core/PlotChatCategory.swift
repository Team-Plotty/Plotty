import SwiftUI

// MARK: - チャット送信カテゴリ（schedule / task / memo）
enum PlotChatCategory: String, CaseIterable, Identifiable {
    case schedule
    case task
    case memo
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .schedule: return "予定"
        case .task: return "タスク"
        case .memo: return "メモ"
        }
    }
    
    /// キーボード表示時のクイックアクション行ラベル
    var quickActionTitle: String {
        switch self {
        case .schedule: return "カレンダー"
        case .task: return "Todo"
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
        case .schedule: return "カレンダーの予定として登録"
        case .task: return "TODO のタスクとして登録"
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
