import SwiftUI

// MARK: - 設定タブ（メモ / TODO などと同じスクロール＋ガラスカードのリズム）
struct SettingsView: View {
    @Environment(\.accountSession) private var accountSession
    @Environment(\.plotTabHorizontalPaging) private var plotTabHorizontalPaging
    
    @Binding var pendingRoute: SettingsRoute?
    @State private var accountSheetPresented = false
    @State private var accountSwitcherPresented = false
    @State private var termsSheetPresented = false
    @State private var privacySheetPresented = false
    @State private var helpSheetPresented = false
    @State private var ossSheetPresented = false
    @State private var aiPersonaSheetPresented = false
    @State private var profileEditSheetPresented = false
    @State private var logoutConfirmPresented = false
    @State private var deleteAccountConfirmPresented = false
    
    init(pendingRoute: Binding<SettingsRoute?> = .constant(nil)) {
        _pendingRoute = pendingRoute
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SettingsGlassSection(title: "アカウント") {
                    if let account = accountSession.currentAccount {
                        SettingsSignedInSummary(account: account)
                        SettingsInsetDivider()
                        SettingsRowChevron(icon: "pencil", label: "プロフィールを編集") {
                            profileEditSheetPresented = true
                        }
                        SettingsInsetDivider()
                    } else {
                        SettingsSignedOutSummary()
                        SettingsInsetDivider()
                    }
                    
                    SettingsRowChevron(icon: "arrow.triangle.2.circlepath", label: "アカウントを切り替え") {
                        accountSwitcherPresented = true
                    }
                    SettingsInsetDivider()
                    
                    SettingsRowChevron(icon: "person.crop.circle", label: "アカウント") {
                        accountSheetPresented = true
                    }
                    SettingsInsetDivider()
                    
                    SettingsDestructiveRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        label: "ログアウト",
                        isEnabled: accountSession.isLoggedIn
                    ) {
                        logoutConfirmPresented = true
                    }
                }
                
                SettingsGlassSection(title: "外観") {
                    ForEach(Array(AppTheme.allCases.enumerated()), id: \.offset) { index, theme in
                        SettingsThemeRow(theme: theme)
                        if index < AppTheme.allCases.count - 1 {
                            SettingsInsetDivider()
                        }
                    }
                }
                
                SettingsGlassSection(title: "AI・地域") {
                    SettingsRowChevron(icon: "sparkles", label: "AI の口調") {
                        aiPersonaSheetPresented = true
                    }
                    SettingsInsetDivider()
                    SettingsTimezoneRow()
                }
                
                SettingsGlassSection(title: "サポート") {
                    SettingsRowChevron(icon: "questionmark.circle", label: "ヘルプ") {
                        helpSheetPresented = true
                    }
                }
                
                SettingsGlassSection(title: "法的情報") {
                    SettingsRowChevron(icon: "doc.text", label: "利用規約") {
                        termsSheetPresented = true
                    }
                    SettingsInsetDivider()
                    SettingsRowChevron(icon: "hand.raised", label: "プライバシーポリシー") {
                        privacySheetPresented = true
                    }
                    SettingsInsetDivider()
                    SettingsRowChevron(icon: "chevron.left.forwardslash.chevron.right", label: "オープンソースライセンス") {
                        ossSheetPresented = true
                    }
                }
                
                SettingsGlassSection(title: "アプリ情報") {
                    SettingsInfoRow(title: "バージョン", value: "1.0.0")
                    SettingsInsetDivider()
                    SettingsInfoRow(title: "ビルド", value: "1")
                }
                
                if accountSession.isLoggedIn {
                    SettingsGlassSection(title: "危険な操作") {
                        SettingsDestructiveRow(icon: "trash", label: "アカウントを削除") {
                            deleteAccountConfirmPresented = true
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(plotTabHorizontalPaging)
        .sheet(isPresented: $accountSheetPresented) {
            NavigationStack {
                AccountView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $accountSwitcherPresented) {
            NavigationStack {
                AccountSwitcherView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $termsSheetPresented) {
            NavigationStack {
                LegalDocumentView(kind: .termsOfService)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $privacySheetPresented) {
            NavigationStack {
                LegalDocumentView(kind: .privacyPolicy)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $helpSheetPresented) {
            NavigationStack {
                HelpView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $ossSheetPresented) {
            NavigationStack {
                OpenSourceLicensesView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $aiPersonaSheetPresented) {
            NavigationStack {
                AIPersonaSettingsView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $profileEditSheetPresented) {
            ProfileEditSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("ログアウトしますか？", isPresented: $logoutConfirmPresented) {
            Button("キャンセル", role: .cancel) {}
            Button("ログアウト", role: .destructive) {
                accountSession.logout()
            }
        } message: {
            Text("ログアウトすると、この端末でのログイン状態が解除されます。再度使うときはアカウントを選び直してください。")
        }
        .alert("アカウントを削除しますか？", isPresented: $deleteAccountConfirmPresented) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                accountSession.deleteAccount()
            }
        } message: {
            Text("この端末のログイン状態が解除されます。クラウド上のデータ削除は API 接続後に有効になります。")
        }
        .onAppear { consumePendingRoute() }
        .onChange(of: pendingRoute) { _, _ in consumePendingRoute() }
    }
    
    private func consumePendingRoute() {
        guard pendingRoute == .account else { return }
        accountSheetPresented = true
        pendingRoute = nil
    }
}

#Preview {
    SettingsView()
        .environment(\.appSettings, AppSettings())
        .environment(\.accountSession, AccountSession())
        .ambientBackground()
        .preferredColorScheme(.dark)
}
