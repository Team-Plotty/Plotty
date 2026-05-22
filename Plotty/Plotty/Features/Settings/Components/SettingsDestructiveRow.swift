import SwiftUI

// MARK: - 破壊的操作用の設定行（ログアウト・アカウント削除など）
struct SettingsDestructiveRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let icon: String
    let label: String
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(destructiveColor)
                    .frame(width: 28, alignment: .center)
                
                Text(label)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(destructiveColor)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(label)
    }
    
    private var destructiveColor: Color {
        Color.red.opacity(colorScheme == .dark ? 0.92 : 0.88)
    }
}
