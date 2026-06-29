import Foundation
import SwiftUI

// MARK: - リソース別の同期状態
enum PlotDataResource: String, CaseIterable {
    case memos
    case todos
    case events

    var entityType: PlotEntityType {
        switch self {
        case .memos: return .memo
        case .todos: return .task
        case .events: return .schedule
        }
    }
}

/// チャット送信 API の結果（ユーザー行 ID + アシスタント表示用メッセージ）。
struct ChatSendResult: Sendable {
    let userMessageId: UUID
    let assistantMessage: ChatMessage
}

// MARK: - アプリ内データ
@Observable
final class PlotDataStore {
    var memos: [MemoItem] = []
    var todos: [TodoItem] = []
    var events: [CalendarEvent] = []

    private let apiClient: PlotAPIClient

    private(set) var syncPhase: [PlotDataResource: PlotAsyncPhase] = [
        .memos: .idle,
        .todos: .idle,
        .events: .idle,
    ]

    init(apiClient: PlotAPIClient = .shared) {
        self.apiClient = apiClient
    }

    /// プレビュー・開発用（サンプルデータ付き）
    static func previewSample() -> PlotDataStore {
        let store = PlotDataStore()
        store.memos = MemoItem.sampleData
        store.todos = TodoItem.sampleData
        store.events = CalendarEvent.sampleData
        return store
    }
    
    func syncPhase(for resource: PlotDataResource) -> PlotAsyncPhase {
        syncPhase[resource] ?? .idle
    }
    
    func isLoading(_ resource: PlotDataResource) -> Bool {
        syncPhase(for: resource) == .loading
    }
    
    func errorMessage(for resource: PlotDataResource) -> String? {
        if case .error(let message) = syncPhase(for: resource) { return message }
        return nil
    }
    
    @MainActor
    func reload(_ resource: PlotDataResource, isOnline: Bool) async {
        guard syncPhase(for: resource) != .loading else { return }

        guard isOnline else {
            syncPhase[resource] = .error("オフラインのため最新データを取得できません。")
            return
        }

        syncPhase[resource] = .loading

        #if DEBUG
        if PlotDebug.simulateDataLoadFailure {
            syncPhase[resource] = .error("データの取得に失敗しました。")
            return
        }
        #endif

        do {
            let items = try await fetchEntities(type: resource.entityType)
            applyFetched(resource, items: items)
            syncPhase[resource] = .idle
        } catch {
            syncPhase[resource] = .error(syncErrorMessage(error, action: "entity_list", resource: resource))
        }
    }

    // MARK: - API

    private func fetchEntities(type: PlotEntityType) async throws -> [PlotEntityListItemDTO] {
        let response: PlotGetEntitiesResponseDTO = try await apiClient.request(
            method: .get,
            path: "api/v1/entities",
            queryItems: [
                URLQueryItem(name: "type", value: type.rawValue),
                URLQueryItem(name: "limit", value: "200"),
            ]
        )
        return response.items
    }

    @MainActor
    private func applyFetched(_ resource: PlotDataResource, items: [PlotEntityListItemDTO]) {
        switch resource {
        case .memos:
            let accents = Dictionary(uniqueKeysWithValues: memos.map { ($0.id, $0.accent) })
            memos = items.compactMap { dto -> MemoItem? in
                guard var item = PlotEntityMapper.memoItem(from: dto) else { return nil }
                if let accent = accents[item.id] {
                    item.accent = accent
                }
                return item
            }
        case .todos:
            todos = items.compactMap { PlotEntityMapper.todoItem(from: $0) }
        case .events:
            let swatches = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0.swatch) })
            events = items.compactMap { dto -> CalendarEvent? in
                guard var item = PlotEntityMapper.calendarEvent(from: dto) else { return nil }
                if let swatch = swatches[item.id] {
                    item.swatch = swatch
                }
                return item
            }
        }
    }

    private func userFacingMessage(for error: Error) -> String {
        if let apiError = error as? PlotAPIError {
            return apiError.localizedDescription
        }
        return error.localizedDescription
    }

    private func syncErrorMessage(_ error: Error, action: String, resource: PlotDataResource) -> String {
        PlotAnalytics.trackFailure(
            action: action,
            error: error,
            screen: resource.analyticsScreen,
            entityType: resource.entityType
        )
        return userFacingMessage(for: error)
    }

    private func requireOnline(_ resource: PlotDataResource, isOnline: Bool) -> Bool {
        guard isOnline else {
            syncPhase[resource] = .error("オフラインのため操作できません。")
            return false
        }
        return true
    }

    private func patchEntity(
        type: PlotEntityType,
        id: UUID,
        body: PlotPatchEntityRequestDTO
    ) async throws -> PlotEntityListItemDTO {
        let response: PlotPatchEntityResponseDTO = try await apiClient.request(
            method: .patch,
            path: type.patchPath(id: id),
            body: body
        )
        return response.entity
    }

    private func deleteEntity(type: PlotEntityType, id: UUID) async throws {
        let _: PlotDeleteEntityResponseDTO = try await apiClient.request(
            method: .delete,
            path: type.deletePath(id: id)
        )
    }

    private func markMutationSuccess(_ resource: PlotDataResource) {
        if case .error = syncPhase[resource] {
            syncPhase[resource] = .idle
        }
    }
    
    func clearSyncError(for resource: PlotDataResource) {
        if case .error = syncPhase[resource] {
            syncPhase[resource] = .idle
        }
    }
    
    func addMemo(_ memo: MemoItem) {
        memos.insert(memo, at: 0)
    }
    
    @MainActor
    @discardableResult
    func updateMemo(_ memo: MemoItem, isOnline: Bool) async -> Bool {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else { return false }
        guard requireOnline(.memos, isOnline: isOnline) else { return false }

        let previous = memos[index]
        let accent = previous.accent
        memos[index] = memo

        do {
            let dto = try await patchEntity(
                type: .memo,
                id: memo.id,
                body: PlotEntityMapper.patchRequest(for: memo)
            )
            memos[index] = PlotEntityMapper.merge(memo, with: dto, accent: accent)
            markMutationSuccess(.memos)
            PlotAnalytics.trackUpdate(entityType: .memo, source: "memo_edit", screen: .memo)
            return true
        } catch {
            memos[index] = previous
            syncPhase[.memos] = .error(syncErrorMessage(error, action: "entity_update", resource: .memos))
            return false
        }
    }
    
    @MainActor
    @discardableResult
    func deleteMemo(id: UUID, isOnline: Bool) async -> Bool {
        guard let index = memos.firstIndex(where: { $0.id == id }) else { return false }
        guard requireOnline(.memos, isOnline: isOnline) else { return false }

        let removed = memos[index]
        memos.remove(at: index)

        do {
            try await deleteEntity(type: .memo, id: id)
            markMutationSuccess(.memos)
            PlotAnalytics.trackDelete(entityType: .memo, source: "memo_delete", screen: .memo)
            return true
        } catch {
            memos.insert(removed, at: index)
            syncPhase[.memos] = .error(syncErrorMessage(error, action: "entity_delete", resource: .memos))
            return false
        }
    }
    
    @MainActor
    @discardableResult
    func toggleMemoPin(id: UUID, isOnline: Bool) async -> Bool {
        guard var memo = memos.first(where: { $0.id == id }) else { return false }
        memo.isPinned.toggle()
        memo.updatedAt = Date()
        return await updateMemo(memo, isOnline: isOnline)
    }
    
    func addTodo(_ todo: TodoItem) {
        todos.insert(todo, at: 0)
    }
    
    @MainActor
    @discardableResult
    func updateTodo(_ todo: TodoItem, isOnline: Bool) async -> Bool {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return false }
        guard requireOnline(.todos, isOnline: isOnline) else { return false }

        let previous = todos[index]
        todos[index] = todo

        do {
            let dto = try await patchEntity(
                type: .task,
                id: todo.id,
                body: PlotEntityMapper.patchRequest(for: todo)
            )
            todos[index] = PlotEntityMapper.merge(todo, with: dto)
            markMutationSuccess(.todos)
            PlotAnalytics.trackUpdate(entityType: .task, source: "todo_edit", screen: .todo)
            return true
        } catch {
            todos[index] = previous
            syncPhase[.todos] = .error(syncErrorMessage(error, action: "entity_update", resource: .todos))
            return false
        }
    }
    
    @MainActor
    @discardableResult
    func deleteTodo(id: UUID, isOnline: Bool) async -> Bool {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return false }
        guard requireOnline(.todos, isOnline: isOnline) else { return false }

        let removed = todos[index]
        todos.remove(at: index)

        do {
            try await deleteEntity(type: .task, id: id)
            markMutationSuccess(.todos)
            PlotAnalytics.trackDelete(entityType: .task, source: "todo_delete", screen: .todo)
            return true
        } catch {
            todos.insert(removed, at: index)
            syncPhase[.todos] = .error(syncErrorMessage(error, action: "entity_delete", resource: .todos))
            return false
        }
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
    }
    
    @MainActor
    @discardableResult
    func updateEvent(_ event: CalendarEvent, isOnline: Bool) async -> Bool {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return false }
        guard requireOnline(.events, isOnline: isOnline) else { return false }

        let previous = events[index]
        let swatch = previous.swatch
        events[index] = event

        do {
            let dto = try await patchEntity(
                type: .schedule,
                id: event.id,
                body: PlotEntityMapper.patchRequest(for: event)
            )
            events[index] = PlotEntityMapper.merge(event, with: dto, swatch: swatch)
            markMutationSuccess(.events)
            PlotAnalytics.trackUpdate(entityType: .schedule, source: "schedule_edit", screen: .calendar)
            return true
        } catch {
            events[index] = previous
            syncPhase[.events] = .error(syncErrorMessage(error, action: "entity_update", resource: .events))
            return false
        }
    }
    
    @MainActor
    @discardableResult
    func deleteEvent(id: UUID, isOnline: Bool) async -> Bool {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return false }
        guard requireOnline(.events, isOnline: isOnline) else { return false }

        let removed = events[index]
        events.remove(at: index)

        do {
            try await deleteEntity(type: .schedule, id: id)
            markMutationSuccess(.events)
            PlotAnalytics.trackDelete(entityType: .schedule, source: "schedule_delete", screen: .calendar)
            return true
        } catch {
            events.insert(removed, at: index)
            syncPhase[.events] = .error(syncErrorMessage(error, action: "entity_delete", resource: .events))
            return false
        }
    }

    // MARK: - ローカルのみ（C5 以前の手動作成・モック用）

    func updateMemoLocally(_ memo: MemoItem) {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        memos[index] = memo
    }

    func deleteMemoLocally(id: UUID) {
        memos.removeAll { $0.id == id }
    }

    func updateTodoLocally(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index] = todo
    }

    func deleteTodoLocally(id: UUID) {
        todos.removeAll { $0.id == id }
    }

    func deleteEventLocally(id: UUID) {
        events.removeAll { $0.id == id }
    }

    // MARK: - チャット（C5 + C7 + E2）

    @MainActor
    func sendChatMessage(
        text: String,
        forcedCategory: PlotChatCategory?,
        clientMessageId: UUID,
        sourceMessageCreatedAt: Date = Date(),
        language: AppLanguage
    ) async throws -> ChatSendResult {
        let request = PlotPostChatMessagesRequestDTO(
            text: text,
            forcedCategory: forcedCategory?.entityType,
            clientMessageId: clientMessageId.uuidString.lowercased()
        )
        let response: PlotPostChatMessagesResponseDTO = try await apiClient.request(
            method: .post,
            path: PlotChatAPI.messagesPath,
            body: request
        )
        PlotChatMapper.applyCreatedEntities(response.createdEntities, to: self)
        for entity in response.createdEntities {
            PlotAnalytics.trackCreate(entityType: entity.type, source: "chat_send", screen: .chat)
        }
        let assistantMessage = PlotChatMapper.assistantMessage(
            from: response,
            sourceBody: text,
            sourceMessageCreatedAt: sourceMessageCreatedAt,
            language: language
        )
        return ChatSendResult(userMessageId: response.messageId, assistantMessage: assistantMessage)
    }

    /// `GET /api/v1/chat/messages`。復号済み履歴を `ChatMessage` 配列で返す（E2）。
    @MainActor
    func fetchChatHistory(language: AppLanguage, limit: Int = 100) async throws -> [ChatMessage] {
        let response: PlotGetChatMessagesResponseDTO = try await apiClient.request(
            method: .get,
            path: PlotChatAPI.messagesPath,
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        )
        return PlotChatMapper.chatMessages(from: response.items, language: language)
    }

    /// `POST /api/v1/chat/reclassify`。成功時は Store の実体を差し替える。
    @MainActor
    func reclassifyEntity(
        summary: ChatRegistrationSummary,
        to targetCategory: PlotChatCategory,
        language: AppLanguage,
        reasonText: String? = nil
    ) async throws -> (confirmationText: String, summary: ChatRegistrationSummary) {
        guard let sourceID = summary.linkedEntityID else {
            throw PlotAPIError.unexpectedResponse(httpStatus: 0, bodyPreview: "linkedEntityID が未設定です")
        }
        guard summary.category != targetCategory else {
            throw PlotAPIError.unexpectedResponse(httpStatus: 0, bodyPreview: "同一カテゴリへの再分類です")
        }

        let request = PlotPostReclassifyRequestDTO(
            source: PlotReclassifySourceDTO(
                type: summary.category.entityType,
                id: sourceID
            ),
            targetType: targetCategory.entityType,
            reasonText: reasonText
        )
        let response: PlotPostReclassifyResponseDTO = try await apiClient.request(
            method: .post,
            path: PlotChatAPI.reclassifyPath,
            body: request
        )
        PlotChatMapper.applyReclassification(
            sourceType: summary.category.entityType,
            sourceID: sourceID,
            migratedEntity: response.migratedEntity,
            to: self
        )
        let newSummary = PlotChatMapper.registrationSummary(
            from: response.migratedEntity,
            sourceBody: summary.sourceBody,
            sourceMessageCreatedAt: summary.sourceMessageCreatedAt,
            language: language
        )
        PlotAnalytics.trackCreate(
            entityType: response.migratedEntity.type,
            source: "chat_reclassify",
            screen: .chat
        )
        PlotAnalytics.trackDelete(
            entityType: summary.category.entityType,
            source: "chat_reclassify",
            screen: .chat
        )
        return (response.confirmationText, newSummary)
    }
}

private extension PlotDataResource {
    var analyticsScreen: PlotAnalyticsScreen {
        switch self {
        case .memos: return .memo
        case .todos: return .todo
        case .events: return .calendar
        }
    }
}

private struct PlotDataStoreKey: EnvironmentKey {
    static let defaultValue = PlotDataStore()
}

extension EnvironmentValues {
    var plotDataStore: PlotDataStore {
        get { self[PlotDataStoreKey.self] }
        set { self[PlotDataStoreKey.self] = newValue }
    }
}
