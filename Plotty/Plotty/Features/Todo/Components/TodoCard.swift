import SwiftUI

// MARK: - タスクカード（カレンダー `EventRow` と同じカード面）
struct TodoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let todo: TodoItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(todo.priority.color.opacity(todo.isCompleted ? 0.4 : 1))
                .frame(width: 4)
                .frame(minHeight: 44)
            
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(todo.isCompleted ? Color.accentColor : Color.secondary)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            
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
                    
                    if let due = todo.dueDate {
                        Label {
                            Text(due, format: .dateTime.month(.abbreviated).day())
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.scaledCaption())
                        .foregroundStyle(secondaryTextColor)
                        .labelStyle(.titleAndIcon)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .plotListCardGlass()
        .contentShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .onTapGesture(perform: onToggle)
        .opacity(todo.isCompleted ? 0.78 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(todo.isCompleted ? "ダブルタップで未完了に戻す" : "ダブルタップで完了にする")
        .accessibilityAddTraits(.isButton)
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
    
    private var accessibilityLabel: String {
        let state = todo.isCompleted ? "完了" : "未完了"
        return "\(todo.title)、\(state)、優先度 \(todo.priority.title)"
    }
}
