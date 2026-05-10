import SwiftUI

// MARK: - Message Role
enum MessageRole {
    case user
    case ai
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var role: MessageRole
    var text: String
    var chips: [String] = []
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if role == .user {
                Spacer(minLength: 60)
            }
            
            if role == .ai {
                aiLineIndicator
            }
            
            VStack(alignment: role == .user ? .trailing : .leading, spacing: Spacing.xs) {
                Text(text)
                    .font(.scaledBodyLarge())
                    .foregroundColor(textColor)
                    .bodyLineSpacing()
                    .multilineTextAlignment(role == .user ? .trailing : .leading)
                
                if !chips.isEmpty {
                    chipsView
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(bubbleBackground)
            
            if role == .ai {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    
    private var textColor: Color {
        switch role {
        case .user:
            return colorScheme == .dark ? .darkTextUser : .lightTextUser
        case .ai:
            return colorScheme == .dark ? .darkTextAI : .lightTextAI
        }
    }
    
    @ViewBuilder
    private var bubbleBackground: some View {
        switch role {
        case .user:
            UserBubbleBackground()
        case .ai:
            AIBubbleBackground()
        }
    }
    
    @ViewBuilder
    private var aiLineIndicator: some View {
        if role == .ai {
            Rectangle()
                .fill(colorScheme == .dark ? Color.darkAILine : Color.lightAILine)
                .frame(width: 2)
                .padding(.trailing, Spacing.xs)
        }
    }
    
    @ViewBuilder
    private var chipsView: some View {
        FlowLayout(spacing: Spacing.xxs) {
            ForEach(chips, id: \.self) { chip in
                Chip(text: chip)
            }
        }
    }
}

// MARK: - Flow Layout for Chips
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
