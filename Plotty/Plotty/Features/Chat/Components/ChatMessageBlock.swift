import SwiftUI

// MARK: - 吹き出し＋確認カードのまとまり
struct ChatMessageBlock: View {
    let message: ChatMessage
    var isReclassifying: Bool = false
    var onReclassify: ((PlotChatCategory) -> Void)?
    var reclassifyDisabledReason: String?
    
    var body: some View {
        ChatBubble(role: message.role, text: message.text, chips: message.chips)
        
        if let summary = message.registrationSummary {
            ChatConfirmationCard(
                summary: summary,
                isReclassifying: isReclassifying,
                onReclassify: onReclassify,
                reclassifyDisabledReason: reclassifyDisabledReason
            )
            .padding(.leading, Spacing.md)
        }
    }
}
