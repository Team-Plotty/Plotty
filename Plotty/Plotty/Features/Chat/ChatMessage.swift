import Foundation

// MARK: - チャットメッセージ
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    var text: String
    let chips: [String]
    let timestamp: Date
    var registrationSummary: ChatRegistrationSummary? = nil
}

extension ChatMessage {
    static var sampleData: [ChatMessage] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return [
            ChatMessage(
                role: .ai,
                text: "昨日のタスクは完了していますか？",
                chips: [],
                timestamp: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: yesterday)!
            ),
            ChatMessage(
                role: .user,
                text: "まだ一部残ってる",
                chips: [],
                timestamp: Calendar.current.date(bySettingHour: 21, minute: 5, second: 0, of: yesterday)!
            ),
            ChatMessage(
                role: .ai,
                text: "こんにちは。予定の確認やメモの整理など、手伝いできることがあれば声をかけてください。",
                chips: ["今日の重点", "カレンダー連携"],
                timestamp: Date().addingTimeInterval(-300)
            ),
        ]
    }
}
