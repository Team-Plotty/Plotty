import SwiftUI

// MARK: - アカウント（設定からシートで開く想定。メイン画面と同じ余白・ガラスカード）
struct AccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accountSession) private var accountSession
    
    @State private var profileEditPresented = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let account = accountSession.currentAccount {
                    profileCard(account)
                    
                    Button {
                        profileEditPresented = true
                    } label: {
                        Label("表示名を編集", systemImage: "pencil")
                            .font(.scaledBodyMedium().weight(.semibold))
                            .foregroundStyle(primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.lg)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    signedOutCard
                }
                
                if let account = accountSession.currentAccount {
                    infoCard(title: "ログイン方式", value: account.provider.title)
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("アカウント")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(primaryTextColor)
                }
                .buttonStyle(GlassIconButtonStyle())
                .accessibilityLabel("閉じる")
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .sheet(isPresented: $profileEditPresented) {
            ProfileEditSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func profileCard(_ account: PlottyAccount) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(iconColor)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(account.displayName)
                    .font(.scaledTitleSmall())
                    .foregroundStyle(primaryTextColor)
                Text(account.email)
                    .font(.scaledBodyMedium())
                    .foregroundStyle(secondaryTextColor)
            }
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }
    
    private var signedOutCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("ログインしていません")
                .font(.scaledTitleSmall())
                .foregroundStyle(primaryTextColor)
            Text("設定の「アカウントを切り替え」から、使うアカウントを選んでください。")
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryTextColor)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private func infoCard(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryTextColor)
            Spacer()
            Text(value)
                .font(.scaledBodyMedium())
                .foregroundStyle(primaryTextColor)
        }
        .padding(Spacing.lg)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        AccountView()
            .environment(\.accountSession, AccountSession())
            .ambientBackground()
    }
    .preferredColorScheme(.dark)
}
