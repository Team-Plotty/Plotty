import SwiftUI

// MARK: - 吹き出し＋確認カードのまとまり
struct ChatMessageBlock: View {
    let message: ChatMessage
    let isReclassifying: Bool
    let onReclassify: ((PlotChatCategory) -> Void)?
    let reclassifyDisabledReason: String?
    /// 届いたばかりの AI 応答なら、本文をタイプライター表示してから確認カードをフェードで出す
    let animatesAppearance: Bool
    let onAppearanceFinished: () -> Void

    /// カードは最初から配置して透明にしておく（後から挿入すると本文の下で行がずれるため）
    @State private var showsCard: Bool

    init(
        message: ChatMessage,
        isReclassifying: Bool = false,
        onReclassify: ((PlotChatCategory) -> Void)? = nil,
        reclassifyDisabledReason: String? = nil,
        animatesAppearance: Bool = false,
        onAppearanceFinished: @escaping () -> Void = {}
    ) {
        self.message = message
        self.isReclassifying = isReclassifying
        self.onReclassify = onReclassify
        self.reclassifyDisabledReason = reclassifyDisabledReason
        self.animatesAppearance = animatesAppearance
        self.onAppearanceFinished = onAppearanceFinished
        _showsCard = State(initialValue: !animatesAppearance)
    }

    var body: some View {
        ChatBubble(
            role: message.role,
            text: message.text,
            chips: message.chips,
            animatesTyping: animatesAppearance,
            onTypingFinished: revealCard
        )
        
        if let summary = message.registrationSummary {
            ChatConfirmationCard(
                summary: summary,
                isReclassifying: isReclassifying,
                onReclassify: onReclassify,
                reclassifyDisabledReason: reclassifyDisabledReason
            )
            .padding(.leading, Spacing.md)
            .opacity(showsCard ? 1 : 0)
            .allowsHitTesting(showsCard)
        }
    }

    private func revealCard() {
        withAnimation(.easeOut(duration: 0.35)) {
            showsCard = true
        }
        onAppearanceFinished()
    }
}
