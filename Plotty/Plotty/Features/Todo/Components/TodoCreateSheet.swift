import SwiftUI

// MARK: - 新規タスク作成シート
struct TodoCreateSheet: View {
    @Binding var isPresented: Bool
    @Binding var draftTitle: String
    @Binding var draftPriority: TodoItem.Priority
    @Binding var draftHasDueDate: Bool
    @Binding var draftDueDate: Date
    let onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    PlotFormCard(title: "内容") {
                        TextField("タスク名", text: $draftTitle)
                            .font(.scaledBodyLarge())
                            .onChange(of: draftTitle) { _, newValue in
                                draftTitle = PlotInputLimits.clamp(newValue, max: PlotInputLimits.title)
                            }
                        PlotCharacterCountFooter(
                            current: draftTitle.count,
                            maximum: PlotInputLimits.title
                        )
                    }
                    
                    PlotFormCard(title: "優先度") {
                        Picker("優先度", selection: $draftPriority) {
                            ForEach(TodoItem.Priority.allCases, id: \.self) { p in
                                Text(p.title).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    PlotFormCard(title: "期限") {
                        Toggle("期限を設定", isOn: $draftHasDueDate)
                        if draftHasDueDate {
                            DatePicker("期限", selection: $draftDueDate, displayedComponents: [.date])
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarPrimarySheetActionButton("追加", action: onAdd)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
