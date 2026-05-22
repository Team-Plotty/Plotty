import SwiftUI

// MARK: - テーマ選択行
struct SettingsThemeRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let theme: AppTheme
    
    var body: some View {
        Button {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                appSettings.theme = theme
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: theme.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, alignment: .center)
                
                Text(theme.displayName)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                Spacer(minLength: 0)
                
                if appSettings.theme == theme {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(textColor)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}
