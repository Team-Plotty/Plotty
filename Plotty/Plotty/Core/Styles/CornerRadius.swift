import SwiftUI

// MARK: - Corner Radius (Apple HIG Compliant - Continuous Squircle)
enum Radius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 36
    static let pill: CGFloat = 999
}

// MARK: - Rounded Rectangle Helpers
extension View {
    func roundedCorner(_ radius: CGFloat, style: RoundedCornerStyle = .continuous) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: style))
    }
    
    func roundedCornerXS() -> some View {
        roundedCorner(Radius.xs)
    }
    
    func roundedCornerSM() -> some View {
        roundedCorner(Radius.sm)
    }
    
    func roundedCornerMD() -> some View {
        roundedCorner(Radius.md)
    }
    
    func roundedCornerLG() -> some View {
        roundedCorner(Radius.lg)
    }
    
    func roundedCornerXL() -> some View {
        roundedCorner(Radius.xl)
    }
    
    func roundedCornerXXL() -> some View {
        roundedCorner(Radius.xxl)
    }
    
    func roundedCornerPill() -> some View {
        roundedCorner(Radius.pill)
    }
}

// MARK: - Chat Bubble Corner Radius
enum BubbleCorners {
    static let user: (topLeading: CGFloat, topTrailing: CGFloat, bottomLeading: CGFloat, bottomTrailing: CGFloat) = (16, 4, 16, 16)
    static let ai: (topLeading: CGFloat, topTrailing: CGFloat, bottomLeading: CGFloat, bottomTrailing: CGFloat) = (4, 16, 16, 16)
}

struct UnevenRoundedRectangleShape: Shape {
    var topLeading: CGFloat
    var topTrailing: CGFloat
    var bottomLeading: CGFloat
    var bottomTrailing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UnevenRoundedRectangle(
            topLeadingRadius: topLeading,
            bottomLeadingRadius: bottomLeading,
            bottomTrailingRadius: bottomTrailing,
            topTrailingRadius: topTrailing,
            style: .continuous
        )
        return path.path(in: rect)
    }
}
