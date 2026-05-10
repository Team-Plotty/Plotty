import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                
                themeSection
                
                aboutSection
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.xl)
            .padding(.bottom, 140)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        Text("設定")
            .font(.scaledDisplayMedium())
            .titleTracking()
            .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("外観")
            
            VStack(spacing: Spacing.xs) {
                ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                    themeRow(theme)
                }
            }
            .glassCard(.medium, radius: Radius.lg)
        }
    }
    
    private func themeRow(_ theme: AppTheme) -> some View {
        Button(action: {
            withAnimation(.quick) {
                appSettings.theme = theme
            }
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: theme.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                
                Text(theme.displayName)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                Spacer()
                
                if appSettings.theme == theme {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionTitle("アプリ情報")
            
            VStack(spacing: 0) {
                infoRow(label: "バージョン", value: "1.0.0")
                Divider()
                    .background(dividerColor)
                infoRow(label: "ビルド", value: "1")
            }
            .glassCard(.medium, radius: Radius.lg)
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.scaledBodyLarge())
                .foregroundStyle(textColor)
            Spacer()
            Text(value)
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryTextColor)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Helpers
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.scaledLabelMedium())
            .foregroundStyle(secondaryTextColor)
            .padding(.leading, Spacing.xs)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? Color.darkBorderSubtle : Color.lightBorderSubtle
    }
}

#Preview {
    SettingsView()
        .ambientBackground()
        .preferredColorScheme(.dark)
}
