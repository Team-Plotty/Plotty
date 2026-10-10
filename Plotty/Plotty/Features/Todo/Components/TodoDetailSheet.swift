import SwiftUI

// MARK: - タスク詳細シート（カード上で省略されたタイトルも全文表示する）
struct TodoDetailSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings

    let todo: TodoItem
    let onClose: () -> Void
    let onEdit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(todo.title)
                            .font(.scaledTitleSmall())
                            .foregroundStyle(textColor)
                            .strikethrough(todo.isCompleted)
                            .textSelection(.enabled)

                        Label(
                            todo.isCompleted ? "完了" : "未完了",
                            systemImage: todo.isCompleted ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.scaledBodyMedium())
                        .foregroundStyle(secondaryTextColor)

                        HStack(spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(todo.priority.color)
                                .frame(width: 4, height: 16)
                            Text("優先度 \(todo.priority.title)")
                        }
                        .font(.scaledBodySmall())
                        .foregroundStyle(secondaryTextColor)

                        Label(dueDateText, systemImage: "calendar")
                            .font(.scaledBodySmall())
                            .foregroundStyle(secondaryTextColor)

                        Text("作成 \(PlotDateFormatter.dateTime(todo.createdAt, language: appSettings.language))")
                            .font(.scaledCaption())
                            .foregroundStyle(tertiaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("編集", action: onEdit)
                    .filledButtonStyle()
            }
            .padding(Spacing.lg)
            .navigationTitle("タスクの詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onClose)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dueDateText: String {
        guard let due = todo.dueDate else { return "期限なし" }
        let language = appSettings.language
        let formatted = todo.hasDueTime
            ? PlotDateFormatter.dateTime(due, language: language)
            : PlotDateFormatter.date(due, language: language)
        return "期限 \(formatted)"
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}
