//
//  ContentView.swift
//  Plotty
//
//  作成: Aloha  2026/05/10
//  タブ切り替え・画面上部のパンくず・下部タブをまとめるルート画面。
//

import SwiftUI

private extension View {
    /// システムの TabBar を非表示にする。`TabView` 直下だけでは効かないことがあるため各タブのルートにも付ける。
    func plottyHideSystemTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
            .toolbarBackground(.hidden, for: .tabBar)
    }
}

/// 標準の `TabView` で画面を切り替え、システムの下タブは隠して自作の `FooterTabBar` を出す構成。
/// 参考記事: [Custom Tab Bars in SwiftUI — Beyond the Default](https://21zerixpm.medium.com/custom-tab-bars-in-swiftui-beyond-the-default-1236071028c5)
struct ContentView: View {
    @Environment(\.appSettings) private var appSettings
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab: TabItem = .chat
    @State private var pendingSettingsRoute: SettingsRoute?
    
    // 各タブの新規作成シート表示状態
    @State private var showMemoCreate = false
    @State private var showTodoCreate = false
    @State private var showCalendarCreate = false
    
    /// FABを表示するタブかどうか
    private var showFAB: Bool {
        [.memo, .todo, .calendar].contains(selectedTab)
    }
    
    var body: some View {
        GlassEffectContainer {
            ZStack {
                AmbientBackground()
                
                TabView(selection: $selectedTab) {
                    MemoView(showCreateSheet: $showMemoCreate)
                        .tag(TabItem.memo)
                        .plottyHideSystemTabBar()
                    TodoView(selectedTab: selectedTab, showCreateSheet: $showTodoCreate)
                        .tag(TabItem.todo)
                        .plottyHideSystemTabBar()
                    ChatTabView(selectedTab: selectedTab)
                        .tag(TabItem.chat)
                        .plottyHideSystemTabBar()
                    CalendarTabView(selectedTab: selectedTab, showCreateSheet: $showCalendarCreate)
                        .tag(TabItem.calendar)
                        .plottyHideSystemTabBar()
                    SettingsView(pendingRoute: $pendingSettingsRoute)
                        .tag(TabItem.settings)
                        .plottyHideSystemTabBar()
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .plottyHideSystemTabBar()
                /// FAB を `ZStack` で重ねているため、タブ内のスクロール領域の下に明示的に余白を確保する
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if showFAB {
                        Color.clear.frame(height: Spacing.fabMainContentBottomInset)
                    }
                }
                
                // 右下のFAB（メモ/TODO/カレンダーでのみ表示）
                if showFAB {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: fabTapped) {
                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .semibold))
                            }
                            .buttonStyle(GlassIconButtonStyle(dimension: 56))
                            .accessibilityLabel(fabAccessibilityLabel)
                            .padding(.trailing, Spacing.screenEdge)
                            .padding(.bottom, Spacing.md)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
        .safeAreaInset(edge: .top, spacing: 0) {
            PlotRootBreadcrumb(
                screenTitle: selectedTab.rootBreadcrumbTitle,
                onAccountTapped: {
                    selectedTab = .settings
                    pendingSettingsRoute = .account
                }
            )
            .padding(.bottom, Spacing.md)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    Rectangle()
                        .glassEffect(.regular, in: Rectangle())
                    
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color.white.opacity(0.04), Color.white.opacity(0.18)]
                                        : [Color.black.opacity(0.06), Color.white.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 0.6)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        /// 下の余白（ホームインジケータ）をレイアウトに反映させる。画面全体を `overlay` で覆うと余白が 0 になりやすいので `safeAreaInset` を使う。
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FooterTabBar(selectedTab: $selectedTab)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var fabAccessibilityLabel: String {
        switch selectedTab {
        case .memo: return "新しいメモ"
        case .todo: return "新しいタスク"
        case .calendar: return "予定を追加"
        default: return "新規作成"
        }
    }
    
    private func fabTapped() {
        switch selectedTab {
        case .memo: showMemoCreate = true
        case .todo: showTodoCreate = true
        case .calendar: showCalendarCreate = true
        default: break
        }
    }
}

#Preview {
    ContentView()
        .environment(\.appSettings, AppSettings())
}
