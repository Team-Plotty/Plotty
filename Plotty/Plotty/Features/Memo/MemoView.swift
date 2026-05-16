import SwiftUI

// MARK: - メモタブの画面
struct MemoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.plotDataStore) private var dataStore
    
    var selectedTab: TabItem = .memo
    @Binding var showCreateSheet: Bool
    
    @State private var editingMemo: MemoItem?
    @State private var selectedAccentFilters: Set<AccentSwatch> = []
    @State private var searchText = ""
    
    @State private var draftTitle = ""
    @State private var draftContent = ""
    @State private var draftAccent: AccentSwatch = .graphite
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                PlotTopSearchRow(text: $searchText, isFocused: $isSearchFocused)
                
                MemoAccentFilterToolbar(
                    selectedAccents: $selectedAccentFilters,
                    resolvedColorScheme: colorScheme
                )
                
                if dataStore.memos.isEmpty {
                    MemoEmptyState(isCompletelyEmpty: true, hint: "")
                } else if filteredMemos.isEmpty {
                    if !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Spacing.xl)
                    } else {
                        MemoEmptyState(isCompletelyEmpty: false, hint: emptyStateHint)
                    }
                } else {
                    MemoListSection(
                        pinnedMemos: pinnedMemos,
                        unpinnedMemos: unpinnedMemos,
                        onEdit: { editingMemo = $0 },
                        onDelete: removeMemo
                    )
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.tabbedScrollBottomInset)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded { _ in isSearchFocused = false }
        )
        .onChange(of: selectedTab) { _, newTab in
            if newTab != .memo { isSearchFocused = false }
        }
        .sheet(isPresented: $showCreateSheet) {
            MemoCreateSheet(
                isPresented: $showCreateSheet,
                draftTitle: $draftTitle,
                draftContent: $draftContent,
                draftAccent: $draftAccent,
                onSave: saveMemo
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingMemo) { memo in
            MemoEditSheet(memo: memo) { updated in
                dataStore.updateMemo(updated)
                editingMemo = nil
            } onCancel: {
                editingMemo = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func saveMemo() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let memo = MemoItem(
            title: title,
            content: draftContent,
            updatedAt: Date(),
            isPinned: false,
            accent: draftAccent
        )
        withAnimation(.standard) {
            dataStore.addMemo(memo)
        }
        showCreateSheet = false
    }
    
    private func removeMemo(id: UUID) {
        withAnimation(.standard) {
            dataStore.deleteMemo(id: id)
        }
    }
    
    private var filteredMemos: [MemoItem] {
        var list = dataStore.memos
        if !selectedAccentFilters.isEmpty {
            list = list.filter { selectedAccentFilters.contains($0.accent) }
        }
        guard !searchText.isEmpty else { return list }
        return list.filter(matchesSearch)
    }
    
    private var pinnedMemos: [MemoItem] {
        filteredMemos.filter(\.isPinned)
    }
    
    private var unpinnedMemos: [MemoItem] {
        filteredMemos.filter { !$0.isPinned }
    }
    
    private func matchesSearch(_ memo: MemoItem) -> Bool {
        memo.title.localizedCaseInsensitiveContains(searchText)
            || memo.content.localizedCaseInsensitiveContains(searchText)
    }
    
    private var emptyStateHint: String {
        if !selectedAccentFilters.isEmpty {
            return "色の絞り込みを解除するか、別の色を選んでください"
        }
        return "検索キーワードを変えてみてください"
    }
}

#Preview {
    MemoView(selectedTab: .memo, showCreateSheet: .constant(false))
        .environment(\.plotDataStore, PlotDataStore())
        .ambientBackground()
        .preferredColorScheme(.dark)
}
