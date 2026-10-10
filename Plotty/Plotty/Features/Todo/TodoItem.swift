import SwiftUI

// MARK: - TODO 項目のデータモデル
struct TodoItem: Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    /// 締切に時刻まで指定したか。false のときは日付だけを扱い、`dueDate` の時刻は表示しない
    var hasDueTime: Bool
    var priority: Priority
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool,
        dueDate: Date?,
        hasDueTime: Bool = false,
        priority: Priority,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.hasDueTime = hasDueTime
        self.priority = priority
        self.createdAt = createdAt
    }
    
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

extension TodoItem {
    /// 日付のみの締切はその日の 23:59:59 にそろえる。
    /// 期限順の並びで同じ日の時刻付きタスクより後ろに来るようにし、サーバーの補完値（当日末）とも一致させる
    static func normalizedDueDate(_ date: Date, hasTime: Bool, calendar: Calendar = .current) -> Date {
        guard !hasTime else { return date }
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }
}

enum TodoSortOrder: String, CaseIterable {
    case dueDate = "期限順"
    case created = "作成順"
}

// MARK: - 本実装時削除（開発用サンプルデータ）
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
