import SwiftUI

// MARK: - ログイン中のアカウント概要
struct SettingsSignedInSummary: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let account: PlottyAccount
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                Text(account.email)
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryTextColor)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ログイン中、\(account.displayName)、\(account.email)")
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
}

// MARK: - 未ログイン時の概要
struct SettingsSignedOutSummary: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 28))
                .foregroundStyle(secondaryTextColor)
                .accessibilityHidden(true)
            
            Text("ログインしていません")
                .font(.scaledBodyLarge())
                .foregroundStyle(secondaryTextColor)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}
