import SwiftUI

// MARK: - アカウント切り替え（設定からシート表示）
struct AccountSwitcherView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accountSession) private var accountSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("使うアカウントを選んでください。切り替えると、この端末に保存されている表示用の設定がアカウントごとに分かれます（API 接続後に本番のデータと同期します）。")
                    .font(.scaledBodySmall())
                    .foregroundStyle(secondaryTextColor)
                
                VStack(spacing: 0) {
                    ForEach(Array(accountSession.availableAccounts.enumerated()), id: \.element.id) { index, account in
                        accountRow(account)
                        if index < accountSession.availableAccounts.count - 1 {
                            insetDivider
                        }
                    }
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("アカウントを切り替え")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
    }
    
    private func accountRow(_ account: PlottyAccount) -> some View {
        let isSelected = accountSession.currentAccount?.id == account.id
        
        return Button {
            accountSession.switchAccount(to: account)
            dismiss()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
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
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel("選択中")
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(account.displayName)、\(account.email)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var insetDivider: some View {
        Divider()
            .background(dividerColor)
            .padding(.leading, Spacing.lg + 28 + Spacing.sm)
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
    NavigationStack {
        AccountSwitcherView()
            .environment(\.accountSession, AccountSession.preview())
            .ambientBackground()
    }
    .preferredColorScheme(.dark)
}
