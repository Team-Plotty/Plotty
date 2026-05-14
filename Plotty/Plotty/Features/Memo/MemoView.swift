import SwiftUI

// MARK: - メモのデータモデル
struct MemoItem: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var updatedAt: Date
    var isPinned: Bool = false
    var accent: AccentSwatch = .graphite
}

// MARK: - メモタブの画面
struct MemoView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var memos: [MemoItem] = MemoItem.sampleData
    /// 色の絞り込み: 空ならすべて表示。色が選ばれていれば、その色のメモだけ表示。
    @State private var selectedAccentFilters: Set<AccentSwatch> = []
    @Binding var showCreateSheet: Bool
    
    @State private var draftTitle = ""
    @State private var draftContent = ""
    @State private var draftAccent: AccentSwatch = .graphite
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                MemoAccentFilterToolbar(
                    selectedAccents: $selectedAccentFilters,
                    resolvedColorScheme: colorScheme
                )
                
                if filteredMemos.isEmpty {
                    emptyState
                } else {
                    memoList
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.floatingAddButtonClearance)
        }
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showCreateSheet) {
            createSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var createSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TextField("タイトル", text: $draftTitle)
                    .font(.scaledBodyLarge())
                    .foregroundStyle(textColor)
                
                TextField("本文（任意）", text: $draftContent, axis: .vertical)
                    .font(.scaledBodyMedium())
                    .foregroundStyle(textColor)
                    .lineLimit(3...8)
                
                Text("カラー")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(secondaryTextColor)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(AccentSwatch.allCases) { swatch in
                        Button {
                            draftAccent = swatch
                        } label: {
                            Circle()
                                .fill(swatch.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            draftAccent == swatch
                                                ? Color.accentColor
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .navigationTitle("新しいメモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { showCreateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ToolbarPrimarySheetActionButton("保存", action: saveMemo)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func openCreateSheet() {
        draftTitle = ""
        draftContent = ""
        draftAccent = .graphite
        showCreateSheet = true
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
            memos.insert(memo, at: 0)
        }
        showCreateSheet = false
    }
    
    private var memoList: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(filteredMemos) { memo in
                MemoCard(memo: memo)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(secondaryTextColor)
            
            if memos.isEmpty {
                Text("メモがありません")
                    .font(.scaledBodyLarge())
                    .foregroundStyle(secondaryTextColor)
                Text("右下の＋から新しいメモを作成")
                    .font(.scaledBodySmall())
                    .foregroundStyle(tertiaryTextColor)
            } else {
                Text("該当するメモがありません")
                    .font(.scaledBodyLarge())
                    .foregroundStyle(secondaryTextColor)
                Text("色の絞り込みを解除するか、別の色を選んでください")
                    .font(.scaledBodySmall())
                    .foregroundStyle(tertiaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
    private var filteredMemos: [MemoItem] {
        if selectedAccentFilters.isEmpty {
            return memos
        }
        return memos.filter { selectedAccentFilters.contains($0.accent) }
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

// MARK: - メモ一覧用ツールバー（色で絞り込み＋新規作成）
private struct MemoAccentFilterToolbar: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedAccents: Set<AccentSwatch>
    /// `GlassEffectContainer` 配下などで環境の外観がズレるのを防ぐ（メモ親から渡す）。
    var resolvedColorScheme: ColorScheme? = nil
    
    private var scheme: ColorScheme {
        resolvedColorScheme ?? colorScheme
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                allFilterButton
                ForEach(AccentSwatch.allCases) { swatch in
                    accentToggle(swatch)
                }
            }
        }
        .id(scheme)
    }
    
    private var allFilterButton: some View {
        let isAll = selectedAccents.isEmpty
        return Button {
            withAnimation(.quick) {
                selectedAccents.removeAll()
            }
        } label: {
            allFilterLabel(isSelected: isAll)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("すべての色を表示")
        .accessibilityAddTraits(isAll ? .isSelected : [])
    }
    
    @ViewBuilder
    private func allFilterLabel(isSelected: Bool) -> some View {
        let strokeColor: Color = isSelected
            ? (scheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.22))
            : Color.clear
        
        if scheme == .dark {
            Text("すべて")
                .font(.scaledCaption())
                .fontWeight(.medium)
                .foregroundStyle(primary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .glassEffect(.regular.interactive(), in: .capsule)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(strokeColor, lineWidth: 1.2)
                )
        } else {
            Text("すべて")
                .font(.scaledCaption())
                .fontWeight(.medium)
                .foregroundStyle(primary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.07))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.black.opacity(0.22) : Color.black.opacity(0.12),
                            lineWidth: isSelected ? 1.2 : 0.5
                        )
                )
        }
    }
    
    private func accentToggle(_ swatch: AccentSwatch) -> some View {
        let on = selectedAccents.contains(swatch)
        let borderColor: Color = on ? Color.accentColor : (scheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.12))
        let borderWidth: CGFloat = on ? 2.5 : 1
        let shadowRadius: CGFloat = on ? 0 : 2
        
        return Button {
            withAnimation(.quick) {
                if on {
                    selectedAccents.remove(swatch)
                } else {
                    selectedAccents.insert(swatch)
                }
            }
        } label: {
            Circle()
                .fill(swatch.color)
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: .black.opacity(0.12), radius: shadowRadius, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(swatch.title)で絞り込み")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
    
    
    private var primary: Color {
        scheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}

// MARK: - メモを一枚のカードとして表示
private struct MemoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let memo: MemoItem
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(memo.accent.color)
                .frame(width: 4)
            
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
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

// MARK: - プレビュー用のダミーデータ
extension MemoItem {
    static var sampleData: [MemoItem] {
        [
            MemoItem(title: "買い物リスト", content: "牛乳、卵、パン、野菜", updatedAt: Date(), isPinned: true, accent: .sage),
            MemoItem(title: "アイデアメモ", content: "新機能のアイデア：音声入力対応、カレンダー連携の強化", updatedAt: Date().addingTimeInterval(-3600), accent: .sky),
            MemoItem(title: "読書メモ", content: "第3章のポイント：習慣化には環境が重要", updatedAt: Date().addingTimeInterval(-86400), accent: .coral),
            MemoItem(title: "リンク集", content: "", updatedAt: Date().addingTimeInterval(-7200), accent: .graphite),
            MemoItem(title: "下書き", content: "ペーパートーン試し", updatedAt: Date().addingTimeInterval(-4000), accent: .paper),
        ]
    }
}

#Preview {
    MemoView(showCreateSheet: .constant(false))
        .ambientBackground()
        .preferredColorScheme(.dark)
}
