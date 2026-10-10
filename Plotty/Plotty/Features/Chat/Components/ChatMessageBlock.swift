import SwiftUI

// MARK: - 吹き出し＋確認カードのまとまり
struct ChatMessageBlock: View {
    let message: ChatMessage
    let onOpenEntity: ((PlotEntityRoute) -> Void)?
    /// 届いたばかりの AI 応答なら、本文をタイプライター表示してから確認カードをフェードで出す
    let animatesAppearance: Bool
    let onAppearanceFinished: () -> Void

    /// カードは最初から配置して透明にしておく（後から挿入すると本文の下で行がずれるため）
    @State private var showsCard: Bool

    init(
        message: ChatMessage,
        onOpenEntity: ((PlotEntityRoute) -> Void)? = nil,
        animatesAppearance: Bool = false,
        onAppearanceFinished: @escaping () -> Void = {}
    ) {
        self.message = message
        self.onOpenEntity = onOpenEntity
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
                onOpen: openAction(for: summary)
            )
            .padding(.leading, Spacing.md)
            .opacity(showsCard ? 1 : 0)
            .allowsHitTesting(showsCard)
        }
    }

    private func openAction(for summary: ChatRegistrationSummary) -> (() -> Void)? {
        guard let route = summary.route, let onOpenEntity else { return nil }
        return { onOpenEntity(route) }
    }

    private func revealCard() {
        withAnimation(.easeOut(duration: 0.35)) {
            showsCard = true
        }
        onAppearanceFinished()
    }
}
