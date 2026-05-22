import SwiftUI

// MARK: - リソース別の同期状態
enum PlotDataResource: String, CaseIterable {
    case memos
    case todos
    case events
}

// MARK: - アプリ内データ（本実装時: API / 永続化ストアに置き換え）
@Observable
final class PlotDataStore {
    // 本実装時削除: 開発用サンプルデータで初期化（API 接続後は空配列 + fetch に置き換え）
    var memos: [MemoItem] = MemoItem.sampleData
    var todos: [TodoItem] = TodoItem.sampleData
    var events: [CalendarEvent] = CalendarEvent.sampleData
    
    private(set) var syncPhase: [PlotDataResource: PlotAsyncPhase] = [
        .memos: .idle,
        .todos: .idle,
        .events: .idle,
    ]
    
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
        // 本実装時削除: API 呼び出しの疑似遅延
        try? await Task.sleep(for: .milliseconds(400))
        
        // 本実装時削除: デバッグ用の意図的失敗（PlotDebug ごと削除可）
        if PlotDebug.simulateDataLoadFailure {
            syncPhase[resource] = .error("データの取得に失敗しました。")
            return
        }
        
        syncPhase[resource] = .idle
    }
    
    func clearSyncError(for resource: PlotDataResource) {
        if case .error = syncPhase[resource] {
            syncPhase[resource] = .idle
        }
    }
    
    func addMemo(_ memo: MemoItem) {
        memos.insert(memo, at: 0)
    }
    
    func updateMemo(_ memo: MemoItem) {
        guard let i = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        var next = memos
        next[i] = memo
        memos = next
    }
    
    func deleteMemo(id: UUID) {
        memos = memos.filter { $0.id != id }
    }
    
    func toggleMemoPin(id: UUID) {
        guard let i = memos.firstIndex(where: { $0.id == id }) else { return }
        var next = memos
        next[i].isPinned.toggle()
        next[i].updatedAt = Date()
        memos = next
    }
    
    func addTodo(_ todo: TodoItem) {
        todos.insert(todo, at: 0)
    }
    
    func updateTodo(_ todo: TodoItem) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[i] = todo
    }
    
    func deleteTodo(id: UUID) {
        todos.removeAll { $0.id == id }
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
    }
    
    func updateEvent(_ event: CalendarEvent) {
        guard let i = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[i] = event
    }
    
    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
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
