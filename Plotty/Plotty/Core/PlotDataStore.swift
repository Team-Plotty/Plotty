import SwiftUI

// MARK: - アプリ内データ（API 接続前の共有ストア）
@Observable
final class PlotDataStore {
    var memos: [MemoItem] = MemoItem.sampleData
    var todos: [TodoItem] = TodoItem.sampleData
    var events: [CalendarEvent] = CalendarEvent.sampleData
    
    func addMemo(_ memo: MemoItem) {
        memos.insert(memo, at: 0)
    }
    
    func updateMemo(_ memo: MemoItem) {
        guard let i = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        memos[i] = memo
    }
    
    func deleteMemo(id: UUID) {
        memos.removeAll { $0.id == id }
    }
    
    func toggleMemoPin(id: UUID) {
        guard let i = memos.firstIndex(where: { $0.id == id }) else { return }
        memos[i].isPinned.toggle()
        memos[i].updatedAt = Date()
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
