import SwiftUI

// MARK: - TODO タブの画面
struct TodoView: View {
    var selectedTab: TabItem = .todo
    @Binding var showCreateSheet: Bool
    
    @Environment(\.plotDataStore) private var dataStore
    @Environment(\.connectivity) private var connectivity
    
    @State private var searchText = ""
    @State private var priorityFilter: TodoItem.Priority?
    @State private var sortOrder: TodoSortOrder = .dueDate
    @State private var editingTodo: TodoItem?
    
    @State private var draftTitle = ""
    @State private var draftPriority: TodoItem.Priority = .medium
    @State private var draftHasDueDate = false
    @State private var draftDueDate = Date()
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        PlotSearchableTabLayout(
            searchText: $searchText,
            isSearchFocused: $isSearchFocused,
            onRefresh: { await reloadTodos() }
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                PlotScreenStatusSection(
                    isOffline: !connectivity.isOnline,
                    errorMessage: dataStore.errorMessage(for: .todos),
                    onRetry: { Task { await reloadTodos() } }
                )
                
                TodoProgressBlock(
                    completedCount: completedCount,
                    totalCount: dataStore.todos.count
                )
                
                TodoFilterSortBar(
                    priorityFilter: $priorityFilter,
                    sortOrder: $sortOrder
                )
                
                if dataStore.todos.isEmpty {
                    ContentUnavailableView(
                        "タスクがありません",
                        systemImage: "checklist",
                        description: Text("右下の＋から新しいタスクを作成できます。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xl)
                } else if incompleteFiltered.isEmpty && completeFiltered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xl)
                } else {
                    if !incompleteFiltered.isEmpty {
                        TodoTaskListSection(
                            title: "未完了",
                            todos: incompleteFiltered,
                            onToggle: toggleCompletion,
                            onEdit: { editingTodo = $0 },
                            onDelete: removeTodo
                        )
                    }
                    
                    if !completeFiltered.isEmpty {
                        TodoTaskListSection(
                            title: "完了",
                            todos: completeFiltered,
                            onToggle: toggleCompletion,
                            onEdit: { editingTodo = $0 },
                            onDelete: removeTodo
                        )
                    }
                }
            }
        }
        .plotListLoading(dataStore.isLoading(.todos))
        .task { await reloadTodos() }
        .onChange(of: connectivity.isOnline) { _, _ in
            if connectivity.isOnline { Task { await reloadTodos() } }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab != .todo { isSearchFocused = false }
        }
        .sheet(isPresented: $showCreateSheet) {
            TodoCreateSheet(
                isPresented: $showCreateSheet,
                draftTitle: $draftTitle,
                draftPriority: $draftPriority,
                draftHasDueDate: $draftHasDueDate,
                draftDueDate: $draftDueDate,
                onAdd: addTodoFromSheet
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingTodo) { todo in
            TodoEditSheet(todo: todo) { updated in
                dataStore.updateTodo(updated)
                editingTodo = nil
            } onCancel: {
                editingTodo = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func addTodoFromSheet() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let due = draftHasDueDate ? draftDueDate : nil
        let newTodo = TodoItem(title: title, isCompleted: false, dueDate: due, priority: draftPriority)
        withAnimation(.standard) {
            dataStore.addTodo(newTodo)
        }
        showCreateSheet = false
    }
    
    private func toggleCompletion(id: UUID) {
        guard var todo = dataStore.todos.first(where: { $0.id == id }) else { return }
        withAnimation(.quick) {
            todo.isCompleted.toggle()
            dataStore.updateTodo(todo)
        }
    }
    
    private func removeTodo(id: UUID) {
        withAnimation(.standard) {
            dataStore.deleteTodo(id: id)
        }
    }
    
    private var baseSorted: [TodoItem] {
        var list = dataStore.todos
        if let priorityFilter {
            list = list.filter { $0.priority == priorityFilter }
        }
        return list.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted && rhs.isCompleted }
            switch sortOrder {
            case .dueDate:
                let l = lhs.dueDate ?? .distantFuture
                let r = rhs.dueDate ?? .distantFuture
                if l != r { return l < r }
            case .created:
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }
            }
            if lhs.priority.rawValue != rhs.priority.rawValue {
                return lhs.priority.rawValue > rhs.priority.rawValue
            }
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        }
    }
    
    private var incompleteFiltered: [TodoItem] {
        baseSorted.filter { !$0.isCompleted && matchesSearch($0) }
    }
    
    private var completeFiltered: [TodoItem] {
        baseSorted.filter { $0.isCompleted && matchesSearch($0) }
    }
    
    private func matchesSearch(_ todo: TodoItem) -> Bool {
        guard !searchText.isEmpty else { return true }
        return todo.title.localizedCaseInsensitiveContains(searchText)
    }
    
    private var completedCount: Int {
        dataStore.todos.filter(\.isCompleted).count
    }
    
    private func reloadTodos() async {
        await dataStore.reload(.todos, isOnline: connectivity.isOnline)
    }
}

#Preview {
    TodoView(showCreateSheet: .constant(false))
        .environment(\.plotDataStore, PlotDataStore())
        .ambientBackground()
        .preferredColorScheme(.dark)
}
