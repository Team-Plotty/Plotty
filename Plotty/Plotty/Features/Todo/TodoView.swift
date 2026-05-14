import SwiftUI

// MARK: - TODO 項目のデータモデル
struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    
    enum Priority: Int, CaseIterable, Hashable {
        case low = 0
        case medium = 1
        case high = 2
        
        var title: String {
            switch self {
            case .low: return "低"
            case .medium: return "中"
            case .high: return "高"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return Color(hex: "#8FA894").opacity(0.9)
            case .medium: return Color(hex: "#8BA7C4").opacity(0.95)
            case .high: return Color(hex: "#C98F8F")
            }
        }
    }
}

// MARK: - TODO タブの画面（リスト・ボタン・検索の HIG を参考にした構成）
/// Apple のヒューマンインターフェイスガイドライン（リスト・ボタン・検索欄）を意識した画面。
/// 参考: [Lists](https://developer.apple.com/design/human-interface-guidelines/lists),
/// [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)。
/// 検索は一覧直上の `PlotTopSearchRow`（タブ切替・空きタップでキーボードを閉じる）。
struct TodoView: View {
    /// 親のタブ（TODO 以外に切り替えたら検索のフォーカスを外す）
    var selectedTab: TabItem = .todo
    @Binding var showCreateSheet: Bool
    
    @State private var todos: [TodoItem] = TodoItem.sampleData
    @State private var searchText = ""
    
    @State private var draftTitle = ""
    @State private var draftPriority: TodoItem.Priority = .medium
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                PlotTopSearchRow(
                    text: $searchText,
                    isFocused: $isSearchFocused
                )
                
                progressBlock
                
                if todos.isEmpty {
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
                        section(title: "未完了", count: incompleteFiltered.count) {
                            ForEach(incompleteFiltered) { todo in
                                todoCard(todo)
                            }
                        }
                    }
                    
                    if !completeFiltered.isEmpty {
                        section(title: "完了", count: completeFiltered.count) {
                            ForEach(completeFiltered) { todo in
                                todoCard(todo)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.floatingAddButtonClearance)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                isSearchFocused = false
            }
        )
        .onChange(of: selectedTab) { _, newTab in
            if newTab != .todo {
                isSearchFocused = false
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - セクション見出し（未完了 / 完了など）
    @ViewBuilder
    private func section<Content: View>(
        title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.scaledLabelMedium())
                    .foregroundStyle(.secondary)
                Text("\(count)")
                    .font(.scaledLabelMedium().monospacedDigit())
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.leading, Spacing.xs)
            
            LazyVStack(spacing: Spacing.sm) {
                content()
            }
        }
    }
    
    // MARK: - 今日の進捗カード（ガラスカードで背景の上に浮かせる）
    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text("今日の進捗")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(completedCount) / \(todos.count)")
                    .font(.scaledBodyMedium().monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .accessibilityLabel("\(completedCount)件完了、全\(todos.count)件")
            }
            
            ProgressView(value: Double(completedCount), total: Double(max(todos.count, 1)))
                .progressViewStyle(.linear)
                .tint(Color.accentColor)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("進捗")
                .accessibilityValue("\(Int(progressFraction * 100))パーセント")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
    
    // MARK: - タスクを一枚のカードとして表示
    private func todoCard(_ todo: TodoItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Button {
                toggleCompletion(id: todo.id)
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(todo.isCompleted ? Color.accentColor : Color.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isCompleted ? "未完了に戻す" : "完了にする")
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(todo.title)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(todo.isCompleted ? Color.secondary : Color.primary)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(2)
                
                HStack(spacing: Spacing.sm) {
                    priorityChip(todo.priority)
                    if let due = todo.dueDate {
                        Label {
                            Text(due, format: .dateTime.month(.abbreviated).day())
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.scaledCaption())
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .opacity(todo.isCompleted ? 0.78 : 1.0)
        .contextMenu {
            Button(role: .destructive) {
                removeTodo(id: todo.id)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
    
    private func priorityChip(_ priority: TodoItem.Priority) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priority.color)
                .frame(width: 6, height: 6)
            Text(priority.title)
                .font(.scaledCaption().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(priority.color.opacity(0.16))
        )
        .accessibilityLabel("優先度 \(priority.title)")
    }
    
    // MARK: - 新規作成シート（ボトムシート）
    private var createSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タスク名", text: $draftTitle)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("内容")
                }
                
                Section {
                    Picker("優先度", selection: $draftPriority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("優先度")
                } footer: {
                    Text("高い優先度のタスクが一覧の上に表示されやすくなります。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { showCreateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarPrimarySheetActionButton("追加", action: addTodoFromSheet)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: - 操作と状態の更新
    private func openCreateSheet() {
        draftTitle = ""
        draftPriority = .medium
        showCreateSheet = true
    }
    
    private func addTodoFromSheet() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let newTodo = TodoItem(title: title, isCompleted: false, dueDate: nil, priority: draftPriority)
        withAnimation(.standard) {
            todos.insert(newTodo, at: 0)
        }
        showCreateSheet = false
    }
    
    private func toggleCompletion(id: UUID) {
        if let i = todos.firstIndex(where: { $0.id == id }) {
            withAnimation(.quick) {
                todos[i].isCompleted.toggle()
            }
        }
    }
    
    private func removeTodo(id: UUID) {
        withAnimation(.standard) {
            todos.removeAll { $0.id == id }
        }
    }
    
    // MARK: - 一覧の並び替え・絞り込み用の計算プロパティ
    private var baseSorted: [TodoItem] {
        todos.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted && rhs.isCompleted }
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
        todos.filter(\.isCompleted).count
    }
    
    private var progressFraction: CGFloat {
        guard !todos.isEmpty else { return 0 }
        return CGFloat(completedCount) / CGFloat(todos.count)
    }
}

// MARK: - プレビュー用のダミーデータ
extension TodoItem {
    static var sampleData: [TodoItem] {
        let cal = Calendar.current
        let today = Date()
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        return [
            TodoItem(title: "デザインシステムのレビュー", isCompleted: true, dueDate: nil, priority: .high),
            TodoItem(title: "チャット機能の実装", isCompleted: false, dueDate: tomorrow, priority: .high),
            TodoItem(title: "カレンダー連携のテスト", isCompleted: false, dueDate: today, priority: .medium),
            TodoItem(title: "ドキュメント更新", isCompleted: false, dueDate: nil, priority: .low),
            TodoItem(title: "バグ修正 #123", isCompleted: true, dueDate: nil, priority: .medium),
        ]
    }
}

#Preview {
    TodoView(showCreateSheet: .constant(false))
        .ambientBackground()
        .preferredColorScheme(.dark)
}
