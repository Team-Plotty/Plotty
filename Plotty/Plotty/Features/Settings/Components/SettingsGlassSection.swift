import SwiftUI

// MARK: - セクション（見出し＋ガラスカード）
struct SettingsGlassSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.scaledLabelMedium())
                .foregroundStyle(secondaryTextColor)
                .padding(.leading, Spacing.xs)
            
            VStack(spacing: 0) {
                content()
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

// MARK: - カード内の区切り線
struct SettingsInsetDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Divider()
            .background(dividerColor)
            .padding(.leading, Spacing.lg)
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? Color.darkBorderSubtle : Color.lightBorderSubtle
    }
}
