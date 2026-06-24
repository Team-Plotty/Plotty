import Foundation

// MARK: - チャット API 定数（Edge Groq timeout と揃える）

enum PlotChatAPI {
    static let responseTimeout: Duration = .seconds(10)
    static let messagesPath = "api/v1/chat/messages"
    static let reclassifyPath = "api/v1/chat/reclassify"
}
