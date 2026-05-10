import SwiftUI

// MARK: - Spacing (8pt Grid System - Apple HIG Compliant)
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    /// Screen edge padding (comfortable breathing room)
    static let screenEdge: CGFloat = 35
    
    /// Chat: tighter than list tabs so bubbles use width naturally
    static let chatHorizontal: CGFloat = 16
}

// MARK: - Spacing View Helpers
extension View {
    func paddingXXS() -> some View {
        padding(Spacing.xxs)
    }
    
    func paddingXS() -> some View {
        padding(Spacing.xs)
    }
    
    func paddingSM() -> some View {
        padding(Spacing.sm)
    }
    
    func paddingMD() -> some View {
        padding(Spacing.md)
    }
    
    func paddingLG() -> some View {
        padding(Spacing.lg)
    }
    
    func paddingXL() -> some View {
        padding(Spacing.xl)
    }
    
    func paddingXXL() -> some View {
        padding(Spacing.xxl)
    }
}
