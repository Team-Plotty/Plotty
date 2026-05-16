import SwiftUI

// MARK: - 優先度フィルタ・並び替え
struct TodoFilterSortBar: View {
    @Binding var priorityFilter: TodoItem.Priority?
    @Binding var sortOrder: TodoSortOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    PlotFilterChip(title: "すべて", isSelected: priorityFilter == nil) {
                        priorityFilter = nil
                    }
                    ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                        PlotFilterChip(title: priority.title, isSelected: priorityFilter == priority) {
                            priorityFilter = priorityFilter == priority ? nil : priority
                        }
                    }
                }
            }
            
            Picker("並び替え", selection: $sortOrder) {
                ForEach(TodoSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
