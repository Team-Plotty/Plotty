import SwiftUI

// MARK: - タスク一覧セクション
struct TodoTaskListSection: View {
    let title: String
    let todos: [TodoItem]
    let onToggle: (UUID) -> Void
    let onEdit: (TodoItem) -> Void
    let onDelete: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.scaledLabelMedium())
                    .foregroundStyle(.secondary)
                Text("\(todos.count)")
                    .font(.scaledLabelMedium().monospacedDigit())
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.leading, Spacing.xs)
            
            LazyVStack(spacing: Spacing.sm) {
                ForEach(todos) { todo in
                    PlotCardActionRow(
                        onEdit: { onEdit(todo) },
                        onDelete: { onDelete(todo.id) }
                    ) {
                        TodoCard(todo: todo) {
                            onToggle(todo.id)
                        }
                    }
                }
            }
        }
    }
}
