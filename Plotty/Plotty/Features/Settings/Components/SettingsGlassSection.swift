import SwiftUI

// MARK: - セクション（見出し＋ガラスカード）
struct SettingsGlassSection<Content: View>: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
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
            .environment(\.plotColorScheme, plotColorScheme)
        }
    }
    
    private var secondaryTextColor: Color {
        PlotColors.textSecondary(plotColorScheme)
    }
}

// MARK: - カード内の区切り線
struct SettingsInsetDivider: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    var body: some View {
        Divider()
            .background(dividerColor)
            .padding(.leading, Spacing.lg)
    }
    
    private var dividerColor: Color {
        plotColorScheme == .dark ? Color.darkBorderSubtle : Color.lightBorderSubtle
    }
}
