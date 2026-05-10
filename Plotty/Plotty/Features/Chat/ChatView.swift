import SwiftUI

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let text: String
    let chips: [String]
    let timestamp: Date
}

// MARK: - Chat View
struct ChatTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var messages: [ChatMessage] = ChatMessage.sampleData
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(messages) { message in
                    ChatBubble(
                        role: message.role,
                        text: message.text,
                        chips: message.chips
                    )
                }
            }
            .padding(.horizontal, Spacing.chatHorizontal)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Sample Data
extension ChatMessage {
    static var sampleData: [ChatMessage] {
        [
            ChatMessage(
                role: .ai,
                text: "こんにちは。予定の確認やメモの整理など、手伝いできることがあれば声をかけてください。",
                chips: ["今日の重点", "カレンダー連携"],
                timestamp: Date().addingTimeInterval(-300)
            ),
            ChatMessage(
                role: .user,
                text: "明日の午後に空きはある？",
                chips: [],
                timestamp: Date().addingTimeInterval(-240)
            ),
            ChatMessage(
                role: .ai,
                text: "明日は 14:00〜 にブロックが空いています。必要ならそこに仮押さえできます。",
                chips: ["14:00 — 空き"],
                timestamp: Date().addingTimeInterval(-180)
            ),
        ]
    }
}

#Preview {
    ChatTabView()
        .ambientBackground()
        .preferredColorScheme(.dark)
}
