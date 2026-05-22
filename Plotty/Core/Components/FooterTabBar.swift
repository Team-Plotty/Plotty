import SwiftUI

// MARK: - Tab Item
enum TabItem: Int, CaseIterable {
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
        case .chat: return ""
        case .calendar: return "カレンダー"
        case .settings: return "設定"
        }
    }
}

// MARK: - Footer Tab Bar
struct FooterTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.rawValue) { tab in
                tabButton(for: tab)
            }
        }
        .frame(height: 60)
        .background(tabBarBackground)
    }
    
    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab.rawValue
        
        Button(action: {
            withAnimation(.quick) {
                selectedTab = tab.rawValue
            }
        }) {
            VStack(spacing: 2) {
                if tab == .chat {
                    chatTabIcon(isSelected: isSelected)
                } else {
                    Image(systemName: isSelected ? tab.icon.active : tab.icon.inactive)
                        .font(.system(size: 22))
                        .foregroundColor(tabIconColor(isSelected: isSelected))
                    
                    Text(tab.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(tabIconColor(isSelected: isSelected))
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func chatTabIcon(isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? TabItem.chat.icon.active : TabItem.chat.icon.inactive)
                .font(.system(size: 24))
                .foregroundColor(tabIconColor(isSelected: isSelected))
            
            if isSelected {
                Circle()
                    .fill(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                    .frame(width: 3, height: 3)
            }
        }
    }
    
    private func tabIconColor(isSelected: Bool) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(isSelected ? 0.92 : 0.28)
        } else {
            return Color.black.opacity(isSelected ? 0.85 : 0.28)
        }
    }
    
    @ViewBuilder
    private var tabBarBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            
            Rectangle()
                .fill(colorScheme == .dark
                      ? Color(hex: "#121110").opacity(0.90)
                      : Color(hex: "#FAF8F4").opacity(0.92))
            
            VStack {
                Rectangle()
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.09)
                          : Color.black.opacity(0.07))
                    .frame(height: 0.5)
                
                Spacer()
            }
        }
    }
}

// MARK: - Tab Bar with Safe Area
struct FooterTabBarWithSafeArea: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            FooterTabBar(selectedTab: $selectedTab)
        }
        .background(Color.clear)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview
#Preview("Footer Tab Bar") {
    struct PreviewWrapper: View {
        @State private var selectedTab = 2
        
        var body: some View {
            ZStack {
                Color(hex: "#0F0E0D")
                    .ignoresSafeArea()
                
                VStack {
                    Text("Selected: \(TabItem(rawValue: selectedTab)?.label ?? "Chat")")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    FooterTabBar(selectedTab: $selectedTab)
                }
            }
        }
    }
    
    return PreviewWrapper()
}
