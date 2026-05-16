import SwiftUI

// MARK: - 吹き出し＋確認カードのまとまり
struct ChatMessageBlock: View {
    let message: ChatMessage
    
    var body: some View {
        ChatBubble(role: message.role, text: message.text, chips: message.chips)
        
        if let summary = message.registrationSummary {
            ChatConfirmationCard(summary: summary)
                .padding(.leading, Spacing.md)
        }
    }
}
