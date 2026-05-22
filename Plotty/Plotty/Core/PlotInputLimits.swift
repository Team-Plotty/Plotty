import Foundation

// MARK: - 入力文字数（docs §2.3）
enum PlotInputLimits {
    static let title = 120
    static let body = 2_000
    static let displayName = 40
    static let location = 100
    static let eventNotes = 500
    static let chatMessage = 2_000
    
    static func clamp(_ text: String, max: Int) -> String {
        String(text.prefix(max))
    }
}
