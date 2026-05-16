import SwiftUI

// MARK: - メモ一覧（ピン留め / その他）
struct MemoListSection: View {
    @Environment(\.plotDataStore) private var dataStore
    
    let pinnedMemos: [MemoItem]
    let unpinnedMemos: [MemoItem]
    let onEdit: (MemoItem) -> Void
    let onDelete: (UUID) -> Void
    
    var body: some View {
        LazyVStack(spacing: Spacing.md) {
            if !pinnedMemos.isEmpty {
                MemoSectionHeader(title: "ピン留め", count: pinnedMemos.count)
                ForEach(pinnedMemos) { memo in
                    memoRow(memo)
                }
            }
            
            if !unpinnedMemos.isEmpty {
                if !pinnedMemos.isEmpty {
                    MemoSectionHeader(title: "その他", count: unpinnedMemos.count)
                }
                ForEach(unpinnedMemos) { memo in
                    memoRow(memo)
                }
            }
        }
    }
    
    private func memoRow(_ memo: MemoItem) -> some View {
        Button {
            onEdit(memo)
        } label: {
            MemoCard(memo: memo)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                dataStore.toggleMemoPin(id: memo.id)
            } label: {
                Label(
                    memo.isPinned ? "ピン留めを外す" : "ピン留め",
                    systemImage: memo.isPinned ? "pin.slash" : "pin"
                )
            }
            Button(role: .destructive) {
                onDelete(memo.id)
            } label: {
                Label("削除", systemImage: "trash")
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
