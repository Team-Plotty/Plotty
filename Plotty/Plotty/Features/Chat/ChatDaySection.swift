import Foundation

// MARK: - 日付ごとのメッセージグループ
struct ChatDaySection: Identifiable {
    let id: String
    let day: Date
    let messages: [ChatMessage]
}
