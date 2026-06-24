//
//  ContentView.swift
//  Plotty
//
//  作成: Aloha  2026/05/10
//  タブ切り替え・画面上部のパンくず・下部タブをまとめるルート画面。
//

import SwiftUI

/// 自作フッタータブで画面を切り替える。横スワイプでページをスライド（`TabView` ページスタイルはキーボードと相性が悪いため未使用）。
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
    
    // 検索欄の表示状態（メモ・TODO用）
    @State private var isSearchExpanded = false
    @State private var memoSearchText = ""
    @State private var todoSearchText = ""
    @FocusState private var isSearchFocused: Bool
    
    @State private var chatDraftMessage = ""
    @State private var chatSendRequested = false
    @FocusState private var isChatComposerFocused: Bool
    @State private var isChatAIProcessing = false
    @State private var isChatComposerPageVisible = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // メインコンテンツ
            mainContent
            
            // タブバー（常に画面下部に固定）
            bottomChrome
        }
        // ZStack 全体でキーボードを無視することで、タブバーが動かなくなる
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // キーボード高さを子ビューに提供（チャット入力欄で使用）
        .plotKeyboardAware()
        // 検索オーバーレイ（最前面に表示）
        .overlay(alignment: .bottom) {
            if isSearchExpanded, showsFloatingSearch {
                floatingSearchOverlay
            }
        }
        .animation(.easeOut(duration: 0.25), value: isSearchExpanded)
        .overlay {
            if selectedTab == .chat, isChatAIProcessing {
                PlotAIScreenBorder()
            }
        }
        .onAppear {
            focusChatComposerIfNeeded()
        }
        .onChange(of: selectedTab) { _, newTab in
            // 検索を閉じる
            if isSearchExpanded {
                closeSearch()
            }
            
            if newTab == .chat {
                focusChatComposerIfNeeded()
            } else {
                dismissChatComposerImmediately()
                isChatAIProcessing = false
            }
        }
    }
    
    @Environment(\.plotDataStore) private var dataStore
    
    private var mainContent: some View {
        ZStack {
            AmbientBackground()
            
            PlotTabPager(selectedTab: $selectedTab) { tab in
                tabPage(for: tab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(PlotChatComposerVisiblePreferenceKey.self) { visible in
            if isChatComposerPageVisible, !visible {
                dismissChatComposerImmediately()
            }
            isChatComposerPageVisible = visible
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
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
                
                // TODOタブの時だけ進捗バーを表示
                if selectedTab == .todo {
                    TodoHeaderProgress(
                        completedCount: dataStore.todos.filter(\.isCompleted).count,
                        totalCount: dataStore.todos.count
                    )
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.xs)
                }
            }
            .padding(.bottom, Spacing.xs)
            .frame(maxWidth: .infinity)
            .background {
                PlotRootChromeGlass()
                    .ignoresSafeArea(edges: .top)
            }
        }
        /// コンテンツ下部にタブバー分の余白を確保
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: Spacing.tabBarHeight)
        }
    }
    
    @ViewBuilder
    private func tabPage(for tab: TabItem) -> some View {
        switch tab {
        case .memo:
            MemoView(
                selectedTab: tab,
                showCreateSheet: $showMemoCreate,
                searchText: $memoSearchText
            )
        case .todo:
            TodoView(
                selectedTab: tab,
                showCreateSheet: $showTodoCreate,
                searchText: $todoSearchText
            )
        case .chat:
            ChatTabView(
                selectedTab: tab,
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
    
    private var showsFloatingSearch: Bool {
        [.memo, .todo].contains(selectedTab)
    }
    
    private var bottomChrome: some View {
        FooterTabBar(selectedTab: $selectedTab)
            .overlay(alignment: .top) {
                // フローティングボタン（タブバーの上に配置）
                if showsFloatingAdd || showsFloatingSearch {
                    HStack {
                        // 検索ボタン（左）
                        if showsFloatingSearch {
                            PlotFloatingSearchButton(
                                accessibilityLabel: "検索",
                                action: searchButtonTapped
                            )
                        }
                        
                        Spacer()
                        
                        // 作成ボタン（右）
                        if showsFloatingAdd {
                            PlotFloatingAddButton(
                                accessibilityLabel: floatingAddAccessibilityLabel,
                                action: fabTapped
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.screenEdge)
                    .offset(y: -(Spacing.floatingAddGapAboveTabBar + 72))
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
    
    /// タブ切替時に入力ドックをアニメなしで即閉じる（ページスライドの残像を防ぐ）。
    private func dismissChatComposerImmediately() {
        PlotTextInputDismiss.postNotification()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isChatComposerFocused = false
            chatCategory = nil
        }
    }
    
    private func fabTapped() {
        dismissTextInputForCurrentTab()
        isSearchExpanded = false
        switch selectedTab {
        case .memo: showMemoCreate = true
        case .todo: showTodoCreate = true
        case .calendar: showCalendarCreate = true
        default: break
        }
    }
    
    private func searchButtonTapped() {
        dismissTextInputForCurrentTab()
        withAnimation(.easeOut(duration: 0.25)) {
            isSearchExpanded = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSearchFocused = true
        }
    }
    
    private func closeSearch() {
        isSearchFocused = false
        withAnimation(.easeOut(duration: 0.25)) {
            isSearchExpanded = false
        }
    }
    
    private var currentSearchText: Binding<String> {
        switch selectedTab {
        case .memo: return $memoSearchText
        case .todo: return $todoSearchText
        default: return .constant("")
        }
    }
    
    @ViewBuilder
    private var floatingSearchOverlay: some View {
        SearchOverlayContent(
            searchText: currentSearchText,
            isSearchFocused: $isSearchFocused,
            placeholder: selectedTab == .memo ? "メモを検索" : "タスクを検索",
            onCancel: closeSearch
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - 検索オーバーレイ（キーボード追従）
private struct SearchOverlayContent: View {
    @Environment(\.keyboardHeight) private var keyboardHeight
    
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    var placeholder: String
    var onCancel: () -> Void
    
    /// キーボード表示時の上方向オフセット（チャット入力欄と同じ計算）
    private var keyboardOffset: CGFloat {
        guard keyboardHeight > 0 else { return 0 }
        let safeAreaBottom: CGFloat = 34
        return keyboardHeight - Spacing.tabBarHeight - safeAreaBottom
    }
    
    var body: some View {
        ZStack {
            // 背景タップで閉じる
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                PlotFloatingSearchField(
                    text: $searchText,
                    isFocused: $isSearchFocused,
                    placeholder: placeholder,
                    onCancel: onCancel
                )
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.bottom, Spacing.chatComposerGapAboveTabBar)
                .offset(y: -keyboardOffset)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.appSettings, AppSettings())
        .environment(\.accountSession, AccountSession.preview())
        .environment(\.plotDataStore, PlotDataStore.previewSample())
        .environment(\.connectivity, ConnectivityMonitor())
}
