import SwiftUI

// MARK: - チャットタブ
private enum ChatScrollAnchor {
    static let bottom = "chatScrollBottom"
}

private enum ChatSendError: Error {
    case timeout
    case api(String)
}

private struct PendingChatRetry: Equatable {
    let body: String
    let forcedCategory: PlotChatCategory?
    let clientMessageId: UUID
}

/// チャット入力ドック（`ChatTabView` でスクロール上に重ねる。背景は付けない）
struct ChatComposerDock: View {
    @Environment(\.connectivity) private var connectivity
    
    @Binding var draftMessage: String
    @Binding var selectedCategory: PlotChatCategory?
    @FocusState.Binding var isComposerFocused: Bool
    @Binding var sendRequested: Bool
    var inferenceModel: ChatCategoryInferenceModel
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
    @Environment(\.accountSession) private var accountSession
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
    @State private var historyPhase: PlotAsyncPhase = .idle
    @State private var lastError: String?
    @State private var pendingRetry: PendingChatRetry?
    @State private var reclassifyingMessageID: UUID?
    @State private var aiTask: Task<Void, Never>?
    @State private var categoryInference = ChatCategoryInferenceModel()
    
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
                inferenceModel: categoryInference,
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
                            } else if case .error = historyPhase {
                                loadChatHistory()
                            } else {
                                lastError = nil
                            }
                        }
                    }

                    if historyPhase == .loading, messages.isEmpty {
                        PlotLoadingOverlay(message: "履歴を読み込んでいます…")
                            .frame(maxWidth: .infinity)
                            .padding(.top, Spacing.xl)
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
                loadChatHistoryIfNeeded()
                scrollToLatestExchange(using: proxy, animated: false)
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab != .chat {
                    isComposerFocused = false
                } else {
                    loadChatHistoryIfNeeded()
                    scrollToLatestExchange(using: proxy, animated: false)
                }
            }
            .onChange(of: accountSession.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    loadChatHistoryIfNeeded(force: true)
                } else {
                    messages = []
                    historyPhase = .idle
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
            .onChange(of: draftMessage) { _, _ in
                refreshCategoryInference()
            }
            .onChange(of: selectedCategory) { _, _ in
                refreshCategoryInference()
            }
            .onChange(of: isComposerFocused) { _, _ in
                refreshCategoryInference()
            }
        }
    }
    
    private var showsEmptyGuide: Bool {
        historyPhase != .loading && !messages.contains(where: { $0.role == .user })
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
            if categoryInference.suggestion != nil, selectedCategory == nil {
                height += Spacing.minTouchTarget + Spacing.xs
            }
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
        
        let forcedCategory = selectedCategory
        let clientMessageId = UUID()
        let userMessage = ChatMessage(role: .user, text: body, chips: [], timestamp: Date())
        messages.append(userMessage)
        draftMessage = ""
        selectedCategory = nil
        isComposerFocused = false
        categoryInference.reset()

        requestAIResponse(
            body: body,
            forcedCategory: forcedCategory,
            clientMessageId: clientMessageId,
            userMessageIndex: messages.count - 1
        )
    }

    private func loadChatHistoryIfNeeded(force: Bool = false) {
        guard accountSession.isAuthenticated else { return }
        guard connectivity.isOnline else { return }
        guard force || historyPhase == .idle else { return }

        loadChatHistory()
    }

    private func loadChatHistory() {
        guard accountSession.isAuthenticated, connectivity.isOnline else { return }

        historyPhase = .loading
        lastError = nil

        Task { @MainActor in
            do {
                let loaded = try await dataStore.fetchChatHistory(language: appSettings.language)
                mergeHistory(loaded)
                historyPhase = .idle
            } catch let error as PlotAPIError {
                historyPhase = .error(error.localizedDescription ?? "履歴の取得に失敗しました。")
                if messages.isEmpty {
                    lastError = error.localizedDescription ?? "履歴の取得に失敗しました。"
                }
            } catch {
                historyPhase = .error("履歴の取得に失敗しました。")
                if messages.isEmpty {
                    lastError = "履歴の取得に失敗しました。"
                }
            }
        }
    }

    private func mergeHistory(_ loaded: [ChatMessage]) {
        guard !loaded.isEmpty else {
            if messages.isEmpty {
                messages = loaded
            }
            return
        }

        var merged = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        for message in messages where merged[message.id] == nil {
            merged[message.id] = message
        }
        messages = merged.values.sorted { $0.timestamp < $1.timestamp }
    }

    private func refreshCategoryInference() {
        categoryInference.updateDraft(
            draftMessage,
            language: appSettings.language,
            isEnabled: isComposerFocused && selectedCategory == nil
        )
    }

    private func requestAIResponse(
        body: String,
        forcedCategory: PlotChatCategory?,
        clientMessageId: UUID,
        userMessageIndex: Int
    ) {
        asyncPhase = .loading
        isAIProcessing = true
        lastError = nil
        pendingRetry = nil

        aiTask?.cancel()
        aiTask = Task {
            do {
                let result = try await fetchAIResponse(
                    body: body,
                    forcedCategory: forcedCategory,
                    clientMessageId: clientMessageId
                )
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if messages.indices.contains(userMessageIndex) {
                        messages[userMessageIndex].id = result.userMessageId
                    }
                    if let existingIndex = messages.firstIndex(where: { $0.id == result.assistantMessage.id }) {
                        messages[existingIndex] = result.assistantMessage
                    } else {
                        messages.append(result.assistantMessage)
                    }
                    asyncPhase = .idle
                    isAIProcessing = false
                    pendingRetry = nil
                }
            } catch is CancellationError {
                return
            } catch ChatSendError.timeout {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    handleTimeout(body: body, forcedCategory: forcedCategory, clientMessageId: clientMessageId)
                }
            } catch ChatSendError.api(let message) {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    lastError = message
                    pendingRetry = PendingChatRetry(
                        body: body,
                        forcedCategory: forcedCategory,
                        clientMessageId: clientMessageId
                    )
                    asyncPhase = .idle
                    isAIProcessing = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    lastError = "応答の取得に失敗しました。"
                    pendingRetry = PendingChatRetry(
                        body: body,
                        forcedCategory: forcedCategory,
                        clientMessageId: clientMessageId
                    )
                    asyncPhase = .idle
                    isAIProcessing = false
                }
            }
        }
    }

    private func fetchAIResponse(
        body: String,
        forcedCategory: PlotChatCategory?,
        clientMessageId: UUID
    ) async throws -> ChatSendResult {
        #if DEBUG
        if PlotDebug.forceChatTimeout {
            try await Task.sleep(for: PlotChatAPI.responseTimeout)
            throw ChatSendError.timeout
        }
        #endif

        return try await withThrowingTaskGroup(of: ChatSendResult.self) { group in
            group.addTask { @MainActor in
                do {
                    return try await dataStore.sendChatMessage(
                        text: body,
                        forcedCategory: forcedCategory,
                        clientMessageId: clientMessageId,
                        language: appSettings.language
                    )
                } catch let error as PlotAPIError {
                    if error.isGroqTimeout {
                        throw ChatSendError.timeout
                    }
                    throw ChatSendError.api(error.localizedDescription ?? "エラーが発生しました")
                }
            }
            group.addTask {
                try await Task.sleep(for: PlotChatAPI.responseTimeout)
                throw ChatSendError.timeout
            }

            guard let result = try await group.next() else {
                throw ChatSendError.timeout
            }
            group.cancelAll()
            return result
        }
    }

    private func handleTimeout(
        body: String,
        forcedCategory: PlotChatCategory?,
        clientMessageId: UUID
    ) {
        lastError = "AI の応答がタイムアウトしました（10秒）。もう一度送信できます。"
        pendingRetry = PendingChatRetry(
            body: body,
            forcedCategory: forcedCategory,
            clientMessageId: clientMessageId
        )
        asyncPhase = .idle
        isAIProcessing = false
    }

    private func retryPendingSend(_ pending: PendingChatRetry) {
        lastError = nil
        let userMessageIndex = messages.lastIndex(where: { $0.role == .user && $0.text == pending.body })
            ?? messages.count - 1
        requestAIResponse(
            body: pending.body,
            forcedCategory: pending.forcedCategory,
            clientMessageId: pending.clientMessageId,
            userMessageIndex: max(userMessageIndex, 0)
        )
    }
    
    private func reclassify(messageID: UUID, to category: PlotChatCategory) {
        guard connectivity.isOnline else {
            lastError = "オフラインのため再分類できません。"
            return
        }
        guard let index = messages.firstIndex(where: { $0.id == messageID }),
              let summary = messages[index].registrationSummary,
              summary.category != category else { return }

        reclassifyingMessageID = messageID
        lastError = nil

        Task { @MainActor in
            do {
                let result = try await dataStore.reclassifyEntity(
                    summary: summary,
                    to: category,
                    language: appSettings.language
                )
                var updated = messages[index]
                updated.registrationSummary = result.summary
                updated.text = result.confirmationText
                messages[index] = updated
                reclassifyingMessageID = nil
            } catch let error as PlotAPIError {
                lastError = error.localizedDescription ?? "再分類に失敗しました。"
                reclassifyingMessageID = nil
            } catch {
                lastError = "再分類に失敗しました。"
                reclassifyingMessageID = nil
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
            .environment(\.plotDataStore, PlotDataStore.previewSample())
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
