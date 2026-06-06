import SwiftUI

// MARK: - メモタブの画面
struct MemoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.plotDataStore) private var dataStore
    @Environment(\.connectivity) private var connectivity
    @Environment(\.plotTabHorizontalPaging) private var plotTabHorizontalPaging
    
    var selectedTab: TabItem = .memo
    @Binding var showCreateSheet: Bool
    @Binding var searchText: String
    
    @State private var editingMemo: MemoItem?
    @State private var selectedAccentFilters: Set<AccentSwatch> = []
    
    @State private var draftTitle = ""
    @State private var draftContent = ""
    @State private var draftAccent: AccentSwatch = .graphite
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                PlotScreenStatusSection(
                    isOffline: !connectivity.isOnline,
                    errorMessage: dataStore.errorMessage(for: .memos),
                    onRetry: { Task { await reloadMemos() } }
                )
                
                MemoAccentFilterToolbar(selectedAccents: $selectedAccentFilters)
                
                if dataStore.memos.isEmpty {
                    MemoEmptyState(isCompletelyEmpty: true, hint: "")
                } else if filteredMemos.isEmpty {
                    if !searchText.isEmpty {
                        PlotSearchEmptyState(searchText: searchText, resource: .memo)
                    } else {
                        MemoEmptyState(isCompletelyEmpty: false, hint: emptyStateHint)
                    }
                } else {
                    MemoListSection(
                        filteredMemoIDs: filteredMemos.map(\.id),
                        onEdit: { editingMemo = $0 },
                        onDelete: removeMemo
                    )
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.tabbedScrollBottomInset)
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(plotTabHorizontalPaging)
        .refreshable { await reloadMemos() }
        .plotListLoading(dataStore.isLoading(.memos))
        .task { await reloadMemos() }
        .onChange(of: connectivity.isOnline) { _, _ in
            if connectivity.isOnline { Task { await reloadMemos() } }
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
            .presentationSizing(.page)
        }
        .sheet(item: $editingMemo) { memo in
            MemoEditSheet(memo: memo) { updated in
                withAnimation(.standard) {
                    dataStore.updateMemo(updated)
                }
                editingMemo = nil
            } onCancel: {
                editingMemo = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationSizing(.page)
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
    
    private func matchesSearch(_ memo: MemoItem) -> Bool {
        memo.title.localizedCaseInsensitiveContains(searchText)
            || memo.content.localizedCaseInsensitiveContains(searchText)
    }
    
    private func reloadMemos() async {
        await dataStore.reload(.memos, isOnline: connectivity.isOnline)
    }
    
    private var emptyStateHint: String {
        if !selectedAccentFilters.isEmpty {
            return "色の絞り込みを解除するか、別の色を選んでください"
        }
        return "検索キーワードを変えてみてください"
    }
}

#Preview {
    MemoView(selectedTab: .memo, showCreateSheet: .constant(false), searchText: .constant(""))
        .environment(\.plotDataStore, PlotDataStore())
        .ambientBackground()
        .preferredColorScheme(.dark)
}
