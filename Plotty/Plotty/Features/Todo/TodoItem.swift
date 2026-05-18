import SwiftUI

// MARK: - TODO 項目のデータモデル
struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    var createdAt: Date = Date()
    
    enum Priority: Int, CaseIterable, Hashable {
        case low = 0
        case medium = 1
        case high = 2
        
        var title: String {
            switch self {
            case .low: return "低"
            case .medium: return "中"
            case .high: return "高"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return Color(hex: "#8FA894").opacity(0.9)
            case .medium: return Color(hex: "#8BA7C4").opacity(0.95)
            case .high: return Color(hex: "#C98F8F")
            }
        }
    }
}

enum TodoSortOrder: String, CaseIterable {
    case dueDate = "期限順"
    case created = "作成順"
}

extension TodoItem {
    static var sampleData: [TodoItem] {
        let cal = Calendar.current
        let today = Date()
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let weekAgo = cal.date(byAdding: .day, value: -7, to: today)!
        return [
            TodoItem(title: "デザインシステムのレビュー", isCompleted: true, dueDate: nil, priority: .high, createdAt: weekAgo),
            TodoItem(title: "チャット機能の実装", isCompleted: false, dueDate: tomorrow, priority: .high, createdAt: today),
            TodoItem(title: "カレンダー連携のテスト", isCompleted: false, dueDate: today, priority: .medium, createdAt: today),
            TodoItem(title: "ドキュメント更新", isCompleted: false, dueDate: nil, priority: .low, createdAt: weekAgo),
            TodoItem(title: "バグ修正 #123", isCompleted: true, dueDate: nil, priority: .medium, createdAt: weekAgo),
        ]
    }
}
