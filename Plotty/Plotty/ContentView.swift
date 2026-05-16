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
    @Environment(\.connectivity) private var connectivity
    
    @State private var selectedTab: TabItem = .chat
    @State private var chatCategory: PlotChatCategory?
    @State private var pendingSettingsRoute: SettingsRoute?
    
    // 各タブの新規作成シート表示状態
    @State private var showMemoCreate = false
    @State private var showTodoCreate = false
    @State private var showCalendarCreate = false
    
    /// チャット入力（`TabView` の外に置き、キーボード・合成の不具合を避ける）
    @State private var chatDraftMessage = ""
    @State private var chatSendRequested = false
    @FocusState private var isChatComposerFocused: Bool
    @State private var isChatAIProcessing = false
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            TabView(selection: $selectedTab) {
                    MemoView(selectedTab: selectedTab, showCreateSheet: $showMemoCreate)
                        .tag(TabItem.memo)
                        .plottyHideSystemTabBar()
                    TodoView(selectedTab: selectedTab, showCreateSheet: $showTodoCreate)
                        .tag(TabItem.todo)
                        .plottyHideSystemTabBar()
                    ChatTabView(
                        selectedTab: selectedTab,
                        draftMessage: $chatDraftMessage,
                        selectedCategory: $chatCategory,
                        isComposerFocused: $isChatComposerFocused,
                        isAIProcessing: $isChatAIProcessing,
                        sendRequested: $chatSendRequested
                    )
                        .tag(TabItem.chat)
                        .plottyHideSystemTabBar()
                    CalendarTabView(showCreateSheet: $showCalendarCreate)
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
        /// タブバーのみ inset。チャット入力は `ChatTabView` 内で重ねる（inset だと不透明な帯になる）。
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                FooterTabBar(selectedTab: $selectedTab)
                
                if showsFloatingAdd {
                    PlotFloatingAddButton(
                        accessibilityLabel: floatingAddAccessibilityLabel,
                        action: fabTapped
                    )
                    .padding(.trailing, Spacing.screenEdge)
                    .offset(y: -(Spacing.tabBarHeight + Spacing.floatingAddGapAboveTabBar))
                }
            }
        }
        .onAppear {
            focusChatComposerIfNeeded()
        }
        .overlay {
            if selectedTab == .chat, isChatAIProcessing {
                PlotAIScreenBorder()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .chat {
                focusChatComposerIfNeeded()
            } else {
                isChatComposerFocused = false
                isChatAIProcessing = false
            }
        }
    }
    
    private var showsFloatingAdd: Bool {
        [.memo, .todo, .calendar].contains(selectedTab)
    }
    
    private var floatingAddAccessibilityLabel: String {
        switch selectedTab {
        case .memo: return "新しいメモ"
        case .todo: return "新しいタスク"
        case .calendar: return "予定を追加"
        default: return "新規作成"
        }
    }
    
    /// チャットタブ表示時にキーボードを出してすぐ入力できるようにする
    private func focusChatComposerIfNeeded() {
        guard selectedTab == .chat else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            isChatComposerFocused = true
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
        .environment(\.accountSession, AccountSession())
        .environment(\.plotDataStore, PlotDataStore())
        .environment(\.connectivity, ConnectivityMonitor())
}
