import SwiftUI

// MARK: - タスクカード（カレンダー `EventRow` と同じカード面）
struct TodoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings
    
    let todo: TodoItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(todo.isCompleted ? Color.accentColor : Color.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isCompleted ? "未完了に戻す" : "完了にする")
            
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(todo.priority.color.opacity(todo.isCompleted ? 0.4 : 1))
                .frame(width: 4)
                .frame(minHeight: 44)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(todo.title)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(todo.isCompleted ? secondaryTextColor : primaryTextColor)
                    .strikethrough(todo.isCompleted)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: Spacing.sm) {
                    Text(todo.priority.title)
                        .font(.scaledCaption())
                        .foregroundStyle(tertiaryTextColor)
                    
                    if let deadlineText {
                        Label {
                            Text(deadlineText)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.scaledCaption())
                        .foregroundStyle(secondaryTextColor)
                        .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .padding(.trailing, Spacing.minTouchTarget - Spacing.xs)
        .opacity(todo.isCompleted ? 0.78 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
    
    /// 端末の言語ではなくアプリの言語設定で整形する（`Text(date, format:)` だと英語端末で "Oct 11" になる）
    private var deadlineText: String? {
        guard let due = todo.dueDate else { return nil }
        return PlotDateFormatter.deadline(due, hasTime: todo.hasDueTime, language: appSettings.language)
    }
    
    private var accessibilityLabel: String {
        let state = todo.isCompleted ? "完了" : "未完了"
        var label = "\(todo.title)、\(state)、優先度 \(todo.priority.title)"
        if let deadlineText {
            label += "、期限 \(deadlineText)"
        }
        return label
    }
}
