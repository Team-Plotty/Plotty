import SwiftUI

// MARK: - ラベル＋値の情報行
struct SettingsInfoRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.scaledBodyLarge())
                .foregroundStyle(textColor)
            Spacer(minLength: 0)
            Text(value)
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryTextColor)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}
