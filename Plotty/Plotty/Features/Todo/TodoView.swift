import SwiftUI

// MARK: - Todo Model
struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    
    enum Priority: Int, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
        
        var color: Color {
            switch self {
            case .low: return Color.white.opacity(0.3)
            case .medium: return Color.white.opacity(0.6)
            case .high: return Color.white.opacity(0.9)
            }
        }
    }
}

// MARK: - Todo View
struct TodoView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var todos: [TodoItem] = TodoItem.sampleData
    @State private var newTodoTitle = ""
    @State private var showingAddField = false
    @FocusState private var isAddFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                
                progressSection
                
                if showingAddField {
                    addTodoField
                }
                
                todoList
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.xl)
            .padding(.bottom, 140)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Text("TODO")
                .font(.scaledDisplayMedium())
                .titleTracking()
                .foregroundStyle(textColor)
            
            Spacer()
            
            Button(action: {
                withAnimation(.standard) {
                    showingAddField.toggle()
                    if showingAddField {
                        isAddFieldFocused = true
                    }
                }
            }) {
                Image(systemName: showingAddField ? "xmark" : "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .buttonStyle(GlassIconButtonStyle())
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("今日の進捗")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                Spacer()
                
                Text("\(completedCount)/\(todos.count)")
                    .font(.scaledBodyMedium())
                    .foregroundStyle(textColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                        .frame(width: geo.size.width * progressPercentage)
                }
            }
            .frame(height: 6)
        }
        .padding(Spacing.md)
        .glassCard(.medium, radius: Radius.md)
    }
    
    // MARK: - Add Todo Field
    private var addTodoField: some View {
        HStack(spacing: Spacing.sm) {
            TextField("新しいタスク...", text: $newTodoTitle)
                .font(.scaledBodyLarge())
                .foregroundStyle(textColor)
                .focused($isAddFieldFocused)
                .onSubmit(addTodo)
            
            Button(action: addTodo) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(newTodoTitle.isEmpty ? secondaryTextColor : textColor)
            }
            .disabled(newTodoTitle.isEmpty)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard(.light, radius: Radius.md)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Todo List
    private var todoList: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(sortedTodos) { todo in
                TodoRow(todo: todo, onToggle: { toggleTodo(todo) })
            }
        }
    }
    
    // MARK: - Helpers
    private var sortedTodos: [TodoItem] {
        todos.sorted { !$0.isCompleted && $1.isCompleted }
    }
    
    private var completedCount: Int {
        todos.filter(\.isCompleted).count
    }
    
    private var progressPercentage: CGFloat {
        guard !todos.isEmpty else { return 0 }
        return CGFloat(completedCount) / CGFloat(todos.count)
    }
    
    private func addTodo() {
        guard !newTodoTitle.isEmpty else { return }
        let newTodo = TodoItem(
            title: newTodoTitle,
            isCompleted: false,
            priority: .medium
        )
        withAnimation(.standard) {
            todos.insert(newTodo, at: 0)
            newTodoTitle = ""
        }
    }
    
    private func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            withAnimation(.quick) {
                todos[index].isCompleted.toggle()
            }
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

// MARK: - Todo Row
private struct TodoRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let todo: TodoItem
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if todo.isCompleted {
                        Circle()
                            .fill(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(colorScheme == .dark ? Color.darkBase : Color.lightBase)
                    }
                }
                
                Text(todo.title)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(todo.isCompleted ? secondaryTextColor : textColor)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(1)
                
                Spacer()
                
                Circle()
                    .fill(todo.priority.color)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .glassCard(todo.isCompleted ? .light : .medium, radius: Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2)
    }
}

// MARK: - Sample Data
extension TodoItem {
    static var sampleData: [TodoItem] {
        [
            TodoItem(title: "デザインシステムのレビュー", isCompleted: true, priority: .high),
            TodoItem(title: "チャット機能の実装", isCompleted: false, priority: .high),
            TodoItem(title: "カレンダー連携のテスト", isCompleted: false, priority: .medium),
            TodoItem(title: "ドキュメント更新", isCompleted: false, priority: .low),
            TodoItem(title: "バグ修正 #123", isCompleted: true, priority: .medium),
        ]
    }
}

#Preview {
    TodoView()
        .ambientBackground()
        .preferredColorScheme(.dark)
}
