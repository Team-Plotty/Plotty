import SwiftUI

// MARK: - Memo Model
struct MemoItem: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var updatedAt: Date
    var isPinned: Bool = false
}

// MARK: - Memo View
struct MemoView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var memos: [MemoItem] = MemoItem.sampleData
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                
                searchBar
                
                if filteredMemos.isEmpty {
                    emptyState
                } else {
                    memoList
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.xl)
            .padding(.bottom, 140)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Text("メモ")
                .font(.scaledDisplayMedium())
                .titleTracking()
                .foregroundStyle(textColor)
            
            Spacer()
            
            Button(action: addNewMemo) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .buttonStyle(GlassIconButtonStyle())
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(secondaryTextColor)
            
            TextField("メモを検索...", text: $searchText)
                .font(.scaledBodyLarge())
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard(.light, radius: Radius.md)
    }
    
    // MARK: - Memo List
    private var memoList: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(filteredMemos) { memo in
                MemoCard(memo: memo)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(secondaryTextColor)
            
            Text("メモがありません")
                .font(.scaledBodyLarge())
                .foregroundStyle(secondaryTextColor)
            
            Text("右上の＋ボタンで新しいメモを作成")
                .font(.scaledBodySmall())
                .foregroundStyle(tertiaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
    // MARK: - Helpers
    private var filteredMemos: [MemoItem] {
        if searchText.isEmpty {
            return memos
        }
        return memos.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func addNewMemo() {
        let newMemo = MemoItem(
            title: "新しいメモ",
            content: "",
            updatedAt: Date()
        )
        withAnimation(.standard) {
            memos.insert(newMemo, at: 0)
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}

// MARK: - Memo Card
private struct MemoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let memo: MemoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(memo.title)
                    .font(.scaledTitleSmall())
                    .foregroundStyle(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                if memo.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
                }
            }
            
            if !memo.content.isEmpty {
                Text(memo.content)
                    .font(.scaledBodySmall())
                    .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)
                    .lineLimit(2)
            }
            
            Text(memo.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.scaledCaption())
                .foregroundStyle(colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(.medium, radius: Radius.lg)
    }
}

// MARK: - Sample Data
extension MemoItem {
    static var sampleData: [MemoItem] {
        [
            MemoItem(title: "買い物リスト", content: "牛乳、卵、パン、野菜", updatedAt: Date(), isPinned: true),
            MemoItem(title: "アイデアメモ", content: "新機能のアイデア：音声入力対応、カレンダー連携の強化", updatedAt: Date().addingTimeInterval(-3600)),
            MemoItem(title: "読書メモ", content: "第3章のポイント：習慣化には環境が重要", updatedAt: Date().addingTimeInterval(-86400)),
        ]
    }
}

#Preview {
    MemoView()
        .ambientBackground()
        .preferredColorScheme(.dark)
}
