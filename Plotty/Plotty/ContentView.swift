//
//  ContentView.swift
//  Plotty
//
//  作成: Aloha  2026/05/10
//  タブ切り替え・画面上部のパンくず・下部タブをまとめるルート画面。
//

import SwiftUI

/// 自作フッタータブで画面を切り替える（`TabView` のページスタイルは TextField のキーボードと相性が悪い）。
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
    
    @State private var chatDraftMessage = ""
    @State private var chatSendRequested = false
    @FocusState private var isChatComposerFocused: Bool
    @State private var isChatAIProcessing = false
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
        .safeAreaInset(edge: .top, spacing: 0) {
            PlotRootBreadcrumb(
                screenTitle: selectedTab.rootBreadcrumbTitle,
                onAccountTapped: {
                    PlotTextInputDismiss.postNotification()
                    isChatComposerFocused = false
                    selectedTab = .settings
                    pendingSettingsRoute = .account
                }
            )
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    dismissTextInputForCurrentTab()
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
        /// 入力＋タブバーをまとめた下端。キーボード表示時は塊ごと上に押し上げる。
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomChrome
        }
        .overlay {
            if selectedTab == .chat, isChatAIProcessing {
                PlotAIScreenBorder()
            }
        }
        .onAppear {
            focusChatComposerIfNeeded()
        }
        .onChange(of: selectedTab) { _, newTab in
            dismissTextInputForCurrentTab()
            if newTab == .chat {
                focusChatComposerIfNeeded()
            } else {
                isChatComposerFocused = false
                isChatAIProcessing = false
            }
        }
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .memo:
            MemoView(selectedTab: selectedTab, showCreateSheet: $showMemoCreate)
        case .todo:
            TodoView(selectedTab: selectedTab, showCreateSheet: $showTodoCreate)
        case .chat:
            ChatTabView(
                selectedTab: selectedTab,
                draftMessage: $chatDraftMessage,
                selectedCategory: $chatCategory,
                isComposerFocused: $isChatComposerFocused,
                isAIProcessing: $isChatAIProcessing,
                sendRequested: $chatSendRequested
            )
        case .calendar:
            CalendarTabView(showCreateSheet: $showCalendarCreate)
        case .settings:
            SettingsView(pendingRoute: $pendingSettingsRoute)
        }
    }
    
    private var showsFloatingAdd: Bool {
        [.memo, .todo, .calendar].contains(selectedTab)
    }
    
    private var bottomChrome: some View {
        VStack(spacing: Spacing.chatComposerGapAboveTabBar) {
            if selectedTab == .chat {
                ChatComposerDock(
                    draftMessage: $chatDraftMessage,
                    selectedCategory: $chatCategory,
                    isComposerFocused: $isChatComposerFocused,
                    sendRequested: $chatSendRequested,
                    isAIProcessing: isChatAIProcessing
                )
            }
            
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
    }
    
    private var floatingAddAccessibilityLabel: String {
        switch selectedTab {
        case .memo: return "新しいメモ"
        case .todo: return "新しいタスク"
        case .calendar: return "予定を追加"
        default: return "新規作成"
        }
    }
    
    /// チャットタブ表示時に入力欄へフォーカス（起動直後はレイアウト確定を待つ）
    private func focusChatComposerIfNeeded() {
        guard selectedTab == .chat else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isChatComposerFocused = true
        }
    }
    
    private func dismissTextInputForCurrentTab() {
        PlotTextInputDismiss.postNotification()
        isChatComposerFocused = false
    }
    
    private func fabTapped() {
        dismissTextInputForCurrentTab()
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
