import SwiftUI

// MARK: - 優先度フィルタ（Apple 標準セグメント）・並び替え
struct TodoFilterSortBar: View {
    @Binding var priorityFilter: TodoItem.Priority?
    @Binding var sortOrder: TodoSortOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("優先度", selection: priorityPickerValue) {
                Text("すべて").tag(Optional<TodoItem.Priority>.none)
                ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                    Text(priority.title).tag(Optional(priority))
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("優先度で絞り込み")
            
            Picker("並び替え", selection: $sortOrder) {
                ForEach(TodoSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var priorityPickerValue: Binding<TodoItem.Priority?> {
        $priorityFilter
    }
}
