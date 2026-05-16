import SwiftUI

// MARK: - チャットタブ
private enum ChatScrollAnchor {
    static let bottom = "chatScrollBottom"
}

private struct ChatComposerDockHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ChatTabView: View {
    @Environment(\.connectivity) private var connectivity
    @Environment(\.plotDataStore) private var dataStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var selectedTab: TabItem
    @Binding var draftMessage: String
    @Binding var selectedCategory: PlotChatCategory?
    @FocusState.Binding var isComposerFocused: Bool
    @Binding var isAIProcessing: Bool
    @Binding var sendRequested: Bool
    
    @State private var messages: [ChatMessage] = ChatMessage.sampleData
    @State private var asyncPhase: PlotAsyncPhase = .idle
    @State private var lastError: String?
    @State private var composerDockHeight: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            messageList
            composerDock
        }
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.md) {
                    if let errorMessage = lastError {
                        PlotErrorBanner(message: errorMessage) {
                            lastError = nil
                        }
                    }
                    
                    ForEach(daySections) { section in
                        ChatDayHeader(day: section.day)
                        
                        ForEach(section.messages) { message in
                            ChatMessageBlock(message: message)
                                .id(message.id)
                        }
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id(ChatScrollAnchor.bottom)
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.lg)
            }
            .contentMargins(.bottom, scrollBottomInset, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                scrollToLatestExchange(using: proxy, animated: false)
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab != .chat {
                    isComposerFocused = false
                } else {
                    scrollToLatestExchange(using: proxy, animated: false)
                }
            }
            .onChange(of: messages.count) { _, _ in
                scrollToLatestExchange(using: proxy)
            }
            .onChange(of: asyncPhase) { _, phase in
                if phase == .idle {
                    scrollToLatestExchange(using: proxy)
                }
            }
            .onChange(of: composerDockHeight) { _, _ in
                scrollToLatestExchange(using: proxy, animated: false)
            }
            .onChange(of: sendRequested) { _, requested in
                guard requested else { return }
                commitDraft()
                sendRequested = false
            }
        }
    }
    
    /// 入力ドックぶん（タブバーは `ContentView` の inset で既に確保済み）
    private var scrollBottomInset: CGFloat {
        let dock = composerDockHeight > 0 ? composerDockHeight : Spacing.chatComposerScrollClearance
        return dock + Spacing.chatComposerGapAboveTabBar
    }
    
    /// クイックアクション＋入力欄（背景帯なし・入力ボックスのみ背景あり）
    private var composerDock: some View {
        VStack(spacing: 0) {
            if !connectivity.isOnline {
                PlotOfflineBanner()
                    .padding(.bottom, Spacing.xs)
            }
            
            ChatComposerBar(
                text: $draftMessage,
                selectedCategory: $selectedCategory,
                isFocused: $isComposerFocused,
                onSend: { sendRequested = true }
            )
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.chatComposerGapAboveTabBar)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ChatComposerDockHeightKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(ChatComposerDockHeightKey.self) { composerDockHeight = $0 }
    }
    
    /// 直近の送信と回答が表示領域の上端に来るようスクロールする
    private func scrollToLatestExchange(using proxy: ScrollViewProxy, animated: Bool = true) {
        guard selectedTab == .chat else { return }
        
        let scrollTarget = messages.last(where: { $0.role == .user })?.id ?? messages.last?.id
        
        let scroll = {
            if let scrollTarget {
                proxy.scrollTo(scrollTarget, anchor: .top)
            } else {
                proxy.scrollTo(ChatScrollAnchor.bottom, anchor: .top)
            }
        }
        
        DispatchQueue.main.async {
            if animated, !reduceMotion {
                withAnimation(.easeOut(duration: 0.25)) {
                    scroll()
                }
            } else {
                scroll()
            }
        }
    }
    
    private var daySections: [ChatDaySection] {
        let cal = Calendar.current
        let sorted = messages.sorted { $0.timestamp < $1.timestamp }
        let grouped = Dictionary(grouping: sorted) { cal.startOfDay(for: $0.timestamp) }
        return grouped.keys.sorted().map { day in
            ChatDaySection(
                id: "\(day.timeIntervalSince1970)",
                day: day,
                messages: grouped[day] ?? []
            )
        }
    }
    
    private func commitDraft() {
        guard connectivity.isOnline else {
            lastError = "オフラインのため送信できません。"
            return
        }
        
        let body = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        
        let category = selectedCategory ?? ChatMockResponder.inferCategory(from: body)
        let userMessage = ChatMessage(role: .user, text: body, chips: [], timestamp: Date())
        messages.append(userMessage)
        draftMessage = ""
        selectedCategory = nil
        isComposerFocused = false
        
        asyncPhase = .loading
        isAIProcessing = true
        lastError = nil
        
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            await MainActor.run {
                let aiMessage = ChatMockResponder.respond(body: body, category: category, dataStore: dataStore)
                messages.append(aiMessage)
                asyncPhase = .idle
                isAIProcessing = false
            }
        }
    }
}

#Preview {
    struct Wrapper: View {
        @State private var draft = ""
        @State private var category: PlotChatCategory?
        @State private var sendRequested = false
        @State private var isAIProcessing = false
        @FocusState private var focused: Bool
        
        var body: some View {
            ChatTabView(
                selectedTab: .chat,
                draftMessage: $draft,
                selectedCategory: $category,
                isComposerFocused: $focused,
                isAIProcessing: $isAIProcessing,
                sendRequested: $sendRequested
            )
            .ambientBackground()
            .environment(\.plotDataStore, PlotDataStore())
            .environment(\.connectivity, ConnectivityMonitor())
            .environment(\.appSettings, AppSettings())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: Spacing.tabBarHeight)
            }
        }
    }
    return Wrapper()
        .preferredColorScheme(.dark)
}
