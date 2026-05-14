import SwiftUI

// MARK: - 設定内の遷移先（パンくずからのディープリンクなど）
enum SettingsRoute: Hashable {
    case account
}

// MARK: - 設定タブ（メモ / TODO などと同じスクロール＋ガラスカードのリズム）
struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    @Binding var pendingRoute: SettingsRoute?
    @State private var accountSheetPresented = false
    
    init(pendingRoute: Binding<SettingsRoute?> = .constant(nil)) {
        _pendingRoute = pendingRoute
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                glassSection(title: "アカウント") {
                    rowChevron(
                        icon: "person.crop.circle",
                        label: "アカウント"
                    ) {
                        accountSheetPresented = true
                    }
                }
                
                glassSection(title: "外観") {
                    ForEach(Array(AppTheme.allCases.enumerated()), id: \.offset) { index, theme in
                        themeRow(theme)
                        if index < AppTheme.allCases.count - 1 {
                            insetDivider
                        }
                    }
                }
                
                glassSection(title: "アプリ情報") {
                    infoRow(title: "バージョン", value: "1.0.0")
                    insetDivider
                    infoRow(title: "ビルド", value: "1")
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $accountSheetPresented) {
            NavigationStack {
                AccountView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear { consumePendingRoute() }
        .onChange(of: pendingRoute) { _, _ in consumePendingRoute() }
    }
    
    private func consumePendingRoute() {
        guard pendingRoute == .account else { return }
        accountSheetPresented = true
        pendingRoute = nil
    }
    
    // MARK: - セクション（見出し＋ガラスカード）
    private func glassSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.scaledLabelMedium())
                .foregroundStyle(secondaryTextColor)
                .padding(.leading, Spacing.xs)
            
            VStack(spacing: 0) {
                content()
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
    
    private func rowChevron(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, alignment: .center)
                
                Text(label)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func themeRow(_ theme: AppTheme) -> some View {
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
    
    private func infoRow(title: String, value: String) -> some View {
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
    
    private var insetDivider: some View {
        Divider()
            .background(dividerColor)
            .padding(.leading, Spacing.lg)
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
        .environment(\.appSettings, AppSettings())
        .ambientBackground()
        .preferredColorScheme(.dark)
}
