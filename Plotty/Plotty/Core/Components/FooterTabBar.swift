import SwiftUI

// MARK: - 下部タブの識別子
enum TabItem: Int, CaseIterable, Hashable {
    case memo = 0
    case todo = 1
    case chat = 2
    case calendar = 3
    case settings = 4
    
    var icon: (inactive: String, active: String) {
        switch self {
        case .memo: return ("doc.text", "doc.text.fill")
        case .todo: return ("checklist", "checklist")
        case .chat: return ("bubble.left", "bubble.left.fill")
        case .calendar: return ("calendar", "calendar")
        case .settings: return ("gearshape", "gearshape.fill")
        }
    }
    
    var label: String {
        switch self {
        case .memo: return "メモ"
        case .todo: return "TODO"
        case .chat: return "チャット"
        case .calendar: return "カレンダー"
        case .settings: return "設定"
        }
    }
    
    /// 画面上部の「Plotty / …」表示用。タブのラベル文字列と違う場合がある。
    var rootBreadcrumbTitle: String {
        switch self {
        case .memo: return "メモ"
        case .todo: return "TODO"
        case .chat: return "チャット"
        case .calendar: return "スケジュール"
        case .settings: return "設定"
        }
    }
}

// MARK: - 自作フッタータブバー（システムの TabBar を隠して使う）
/// タブ行のガラス背景だけホームインジケータまで伸ばす（親全体の `ignoresSafeArea` は使わない）。
struct FooterTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .frame(height: Spacing.tabBarHeight)
        .frame(maxWidth: .infinity)
        .background {
            tabBarBackground
                .ignoresSafeArea(edges: .bottom)
        }
    }
    
    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab
        
        Button(action: {
            PlotTextInputDismiss.postNotification()
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.icon.active : tab.icon.inactive)
                    .font(.system(size: 22))
                    .foregroundColor(tabIconColor(isSelected: isSelected))
                
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(tabIconColor(isSelected: isSelected))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func tabIconColor(isSelected: Bool) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(isSelected ? 0.92 : 0.30)
        } else {
            return Color.black.opacity(isSelected ? 0.85 : 0.32)
        }
    }
    
    @ViewBuilder
    private var tabBarBackground: some View {
        ZStack {
            Rectangle()
                .glassEffect(.regular, in: Rectangle())
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.18), Color.white.opacity(0.04)]
                                : [Color.white.opacity(0.7), Color.black.opacity(0.06)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.6)
                Spacer()
            }
        }
    }
}
