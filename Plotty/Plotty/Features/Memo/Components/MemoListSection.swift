import SwiftUI

// MARK: - メモ一覧（ピン留め / その他）
struct MemoListSection: View {
    @Environment(\.plotDataStore) private var dataStore
    
    /// 検索・色フィルタ済みの表示順 ID（カード表示はストアから最新を参照）
    let filteredMemoIDs: [UUID]
    let onEdit: (MemoItem) -> Void
    let onDelete: (UUID) -> Void
    
    var body: some View {
        LazyVStack(spacing: Spacing.md) {
            if !pinnedIDs.isEmpty {
                MemoSectionHeader(title: "ピン留め", count: pinnedIDs.count)
                ForEach(pinnedIDs, id: \.self) { id in
                    memoRow(id: id)
                }
            }
            
            if !unpinnedIDs.isEmpty {
                if !pinnedIDs.isEmpty {
                    MemoSectionHeader(title: "その他", count: unpinnedIDs.count)
                }
                ForEach(unpinnedIDs, id: \.self) { id in
                    memoRow(id: id)
                }
            }
        }
    }
    
    private var pinnedIDs: [UUID] {
        filteredMemoIDs.filter { id in
            dataStore.memos.first(where: { $0.id == id })?.isPinned == true
        }
    }
    
    private var unpinnedIDs: [UUID] {
        filteredMemoIDs.filter { id in
            dataStore.memos.first(where: { $0.id == id })?.isPinned != true
        }
    }
    
    private func memo(for id: UUID) -> MemoItem? {
        dataStore.memos.first(where: { $0.id == id })
    }
    
    @ViewBuilder
    private func memoRow(id: UUID) -> some View {
        if let memo = memo(for: id) {
            PlotCardActionRow(
                onEdit: { onEdit(memo) },
                onDelete: { onDelete(id) },
                pinAction: PlotCardMenuButton.PinAction(
                    title: memo.isPinned ? "ピン留めを外す" : "ピン留め",
                    systemImage: memo.isPinned ? "pin.slash" : "pin",
                    handler: {
                        withAnimation(.standard) {
                            dataStore.toggleMemoPin(id: id)
                        }
                    }
                )
            ) {
                MemoCard(memo: memo)
            }
        }
    }
}

// MARK: - セクション見出し
struct MemoSectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
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
    }
}
