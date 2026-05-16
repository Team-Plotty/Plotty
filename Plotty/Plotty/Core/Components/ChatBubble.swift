import SwiftUI

// MARK: - メッセージの話者（ユーザー or AI）
enum MessageRole {
    case user
    case ai
}

// MARK: - チャットの吹き出し（テキスト＋任意のチップ行）
struct ChatBubble: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var role: MessageRole
    var text: String
    var chips: [String] = []
    
    var body: some View {
        if role == .user {
            userBubble
        } else {
            aiPlainMessage
        }
    }
    
    // MARK: - ユーザー（吹き出し）
    
    private var userBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 60)
            
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(text)
                    .font(.scaledBodyLarge())
                    .foregroundColor(userTextColor)
                    .bodyLineSpacing()
                    .multilineTextAlignment(.trailing)
                
                if !chips.isEmpty {
                    userChipsView
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .glassEffect(.regular, in: userBubbleShape)
        }
    }
    
    // MARK: - AI（背景なし・本文のみ）
    
    private var aiPlainMessage: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(text)
                    .font(.scaledBodyLarge())
                    .foregroundColor(aiTextColor)
                    .bodyLineSpacing()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !chips.isEmpty {
                    aiChipsView
                }
            }
            
            Spacer(minLength: 60)
        }
    }
    
    private var userTextColor: Color {
        colorScheme == .dark ? .darkTextUser : .lightTextUser
    }
    
    private var aiTextColor: Color {
        colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary
    }
    
    private var userBubbleShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: BubbleCorners.user.topLeading,
            bottomLeadingRadius: BubbleCorners.user.bottomLeading,
            bottomTrailingRadius: BubbleCorners.user.bottomTrailing,
            topTrailingRadius: BubbleCorners.user.topTrailing,
            style: .continuous
        )
    }
    
    @ViewBuilder
    private var userChipsView: some View {
        FlowLayout(spacing: Spacing.xxs) {
            ForEach(chips, id: \.self) { chip in
                Chip(
                    text: chip,
                    resolvedColorScheme: colorScheme,
                    glassStyle: .nestedInGlass
                )
            }
        }
    }
    
    @ViewBuilder
    private var aiChipsView: some View {
        FlowLayout(spacing: Spacing.xxs) {
            ForEach(chips, id: \.self) { chip in
                Chip(
                    text: chip,
                    resolvedColorScheme: colorScheme,
                    glassStyle: .standalone
                )
            }
        }
    }
}

// MARK: - チップ用の折り返しレイアウト
/// 横方向に詰め、幅が足りなくなったら次の行へ回すレイアウト（チップの折り返し用）。
struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        let maxAvailableWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxAvailableWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }
        
        return (positions, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}
