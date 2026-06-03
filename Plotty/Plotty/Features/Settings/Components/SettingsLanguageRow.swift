import SwiftUI

// MARK: - 言語選択行
struct SettingsLanguageRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let language: AppLanguage
    
    var body: some View {
        Button {
            appSettings.language = language
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: language.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, alignment: .center)
                
                Text(language.displayName)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                Spacer(minLength: 0)
                
                if appSettings.language == language {
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
