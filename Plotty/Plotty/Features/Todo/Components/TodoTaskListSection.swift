import SwiftUI

// MARK: - タスク一覧セクション
struct TodoTaskListSection: View {
    let title: String
    let todos: [TodoItem]
    let onToggle: (UUID) -> Void
    /// カードのタップとメニューの「編集」で共通（閲覧専用の詳細は挟まず、そのまま編集を開く）
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
                        // カード内に完了チェックのボタンがあるため Button で包まずタップ判定を付ける
                        // （子のボタンが優先されるので、チェック部分のタップは完了切り替えのまま）
                        TodoCard(todo: todo) {
                            onToggle(todo.id)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onEdit(todo) }
                        .accessibilityAction(named: "編集") { onEdit(todo) }
                    }
                }
            }
        }
    }
}
