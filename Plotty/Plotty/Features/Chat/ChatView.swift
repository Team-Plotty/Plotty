import SwiftUI

// MARK: - チャットタブ
private enum ChatScrollAnchor {
    static let bottom = "chatScrollBottom"
}

private enum ChatSendError: Error {
    case timeout
}

private struct PendingChatRetry: Equatable {
    let body: String
    let category: PlotChatCategory
}

/// チャット入力ドック（`ChatTabView` でスクロール上に重ねる。背景は付けない）
struct ChatComposerDock: View {
    @Environment(\.connectivity) private var connectivity
    
    @Binding var draftMessage: String
    @Binding var selectedCategory: PlotChatCategory?
    @FocusState.Binding var isComposerFocused: Bool
    @Binding var sendRequested: Bool
    var isAIProcessing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if !connectivity.isOnline {
                PlotOfflineBanner()
                    .padding(.bottom, Spacing.xs)
            }
            
            ChatComposerBar(
                text: $draftMessage,
                selectedCategory: $selectedCategory,
                isFocused: $isComposerFocused,
                isAIProcessing: isAIProcessing,
                onSend: { sendRequested = true }
            )
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.xs)
    }
}

struct ChatTabView: View {
    @Environment(\.connectivity) private var connectivity
    @Environment(\.plotDataStore) private var dataStore
    @Environment(\.appSettings) private var appSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.plotTabHorizontalPaging) private var plotTabHorizontalPaging
    @Environment(\.keyboardHeight) private var keyboardHeight
    
    var selectedTab: TabItem
    @Binding var draftMessage: String
    @Binding var selectedCategory: PlotChatCategory?
    @FocusState.Binding var isComposerFocused: Bool
    @Binding var isAIProcessing: Bool
    @Binding var sendRequested: Bool
    
    @State private var messages: [ChatMessage] = []
    @State private var asyncPhase: PlotAsyncPhase = .idle
    @State private var lastError: String?
    @State private var pendingRetry: PendingChatRetry?
    @State private var reclassifyingMessageID: UUID?
    @State private var aiTask: Task<Void, Never>?
    
    /// キーボード表示時の入力欄の上方向オフセット
    private var composerKeyboardOffset: CGFloat {
        guard keyboardHeight > 0 else { return 0 }
        // キーボード高さからタブバー高さとセーフエリアを引いた分だけ上に移動
        // 典型的なセーフエリア(ホームインジケータ)は約34pt
        let safeAreaBottom: CGFloat = 34
        return keyboardHeight - Spacing.tabBarHeight - safeAreaBottom
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            messageList
            
            ChatComposerDock(
                draftMessage: $draftMessage,
                selectedCategory: $selectedCategory,
                isComposerFocused: $isComposerFocused,
                sendRequested: $sendRequested,
                isAIProcessing: isAIProcessing
            )
            .padding(.bottom, Spacing.chatComposerGapAboveTabBar)
            .offset(y: -composerKeyboardOffset)
        }
        .onDisappear {
            aiTask?.cancel()
        }
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.md) {
                    if showsEmptyGuide {
                        ChatEmptyGuideCard()
                    }
                    
                    if let errorMessage = lastError {
                        PlotErrorBanner(message: errorMessage) {
                            if let pendingRetry {
                                retryPendingSend(pendingRetry)
                            } else {
                                lastError = nil
                            }
                        }
                    }
                    
                    ForEach(daySections) { section in
                        ChatDayHeader(day: section.day)
                        
                        ForEach(section.messages) { message in
                            ChatMessageBlock(
                                message: message,
                                isReclassifying: reclassifyingMessageID == message.id,
                                onReclassify: message.registrationSummary != nil
                                    ? { category in reclassify(messageID: message.id, to: category) }
                                    : nil
                            )
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
            .scrollDisabled(plotTabHorizontalPaging)
            .plotDismissTextInputWhenTappingOutside(isFocused: $isComposerFocused)
            .plotDismissTextInputOnNotification(isFocused: $isComposerFocused)
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
            .onChange(of: isComposerFocused) { _, focused in
                if focused {
                    scrollToLatestExchange(using: proxy, animated: false)
                }
            }
            .onChange(of: sendRequested) { _, requested in
                guard requested else { return }
                commitDraft()
                sendRequested = false
            }
        }
    }
    
    private var showsEmptyGuide: Bool {
        !messages.contains(where: { $0.role == .user })
    }
    
    /// 入力ドック（オーバーレイ）の高さ分だけ末尾余白を確保する。
    private var scrollBottomInset: CGFloat {
        var height = PlotChatComposerMetrics.minHeightCompact + Spacing.xs * 2
        if selectedCategory != nil {
            height += PlotChatComposerMetrics.minHeightWithChip - PlotChatComposerMetrics.minHeightCompact
        }
        if isComposerFocused {
            let rowCount = CGFloat(PlotChatCategory.quickActionOrder.count)
            height += rowCount * Spacing.minTouchTarget + Spacing.xxs * 2 + Spacing.xs
        }
        return height + Spacing.chatComposerGapAboveTabBar + Spacing.md
    }
    
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
        
        let body = PlotInputLimits.clamp(
            draftMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            max: PlotInputLimits.chatMessage
        )
        guard !body.isEmpty else { return }
        
        let category = selectedCategory ?? ChatMockResponder.inferCategory(from: body) // 本実装時削除: モック推論
        let userMessage = ChatMessage(role: .user, text: body, chips: [], timestamp: Date())
        messages.append(userMessage)
        draftMessage = ""
        selectedCategory = nil
        isComposerFocused = false
        
        requestAIResponse(body: body, category: category)
    }
    
    private func requestAIResponse(body: String, category: PlotChatCategory) {
        asyncPhase = .loading
        isAIProcessing = true
        lastError = nil
        pendingRetry = nil
        
        aiTask?.cancel()
        aiTask = Task {
            do {
                let aiMessage = try await fetchAIResponse(body: body, category: category)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    messages.append(aiMessage)
                    asyncPhase = .idle
                    isAIProcessing = false
                    pendingRetry = nil
                }
            } catch is CancellationError {
                return
            } catch ChatSendError.timeout {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    handleTimeout(body: body, category: category)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    lastError = "応答の取得に失敗しました。"
                    pendingRetry = PendingChatRetry(body: body, category: category)
                    asyncPhase = .idle
                    isAIProcessing = false
                }
            }
        }
    }
    
    // 本実装時削除: ChatMockResponder を本番 AI API 呼び出しに置き換え
    private func fetchAIResponse(body: String, category: PlotChatCategory) async throws -> ChatMessage {
        // 本実装時削除: デバッグ用タイムアウト強制
        if PlotDebug.forceChatTimeout {
            try await Task.sleep(for: ChatMockResponder.responseTimeout)
            throw ChatSendError.timeout
        }
        
        return try await withThrowingTaskGroup(of: ChatMessage.self) { group in
            group.addTask { @MainActor in
                // 本実装時削除: モック応答の疑似遅延
                try await Task.sleep(for: .milliseconds(900))
                if Task.isCancelled { throw CancellationError() }
                return ChatMockResponder.respond(body: body, category: category, dataStore: dataStore, language: appSettings.language)
            }
            group.addTask {
                try await Task.sleep(for: ChatMockResponder.responseTimeout)
                throw ChatSendError.timeout
            }
            
            guard let result = try await group.next() else {
                throw ChatSendError.timeout
            }
            group.cancelAll()
            return result
        }
    }
    
    private func handleTimeout(body: String, category: PlotChatCategory) {
        lastError = "AI の応答がタイムアウトしました（10秒）。もう一度送信できます。"
        pendingRetry = PendingChatRetry(body: body, category: category)
        asyncPhase = .idle
        isAIProcessing = false
    }
    
    private func retryPendingSend(_ pending: PendingChatRetry) {
        lastError = nil
        requestAIResponse(body: pending.body, category: pending.category)
    }
    
    private func reclassify(messageID: UUID, to category: PlotChatCategory) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }),
              let summary = messages[index].registrationSummary,
              summary.category != category else { return }
        
        reclassifyingMessageID = messageID
        
        Task { @MainActor in
            // 本実装時削除: モック再分類
            let newSummary = ChatMockResponder.reclassify(
                summary: summary,
                to: category,
                dataStore: dataStore,
                language: appSettings.language
            )
            var updated = messages[index]
            updated.registrationSummary = newSummary
            updated.text = reclassifyConfirmationText(for: category)
            messages[index] = updated
            reclassifyingMessageID = nil
        }
    }
    
    private func reclassifyConfirmationText(for category: PlotChatCategory) -> String {
        switch (category, appSettings.language) {
        case (.schedule, .japanese): return "カレンダーに登録し直したよ！"
        case (.schedule, .english): return "Moved to calendar!"
        case (.task, .japanese): return "ToDoに登録し直したよ！"
        case (.task, .english): return "Moved to ToDo!"
        case (.memo, .japanese): return "メモに登録し直したよ！"
        case (.memo, .english): return "Moved to memo!"
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
