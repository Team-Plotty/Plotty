import SwiftUI

// MARK: - 検索欄固定＋一覧タップでフォーカス解除（メモ / TODO）
struct PlotSearchableTabLayout<Content: View>: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    var onRefresh: (() async -> Void)?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: Spacing.lg) {
                PlotTopSearchRow(text: $searchText, isFocused: $isSearchFocused)
                    .padding(.horizontal, Spacing.screenEdge)
                
                listScrollView(in: geometry)
            }
            .padding(.top, Spacing.lg)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .plotDismissTextInputOnNotification(isFocused: $isSearchFocused)
    }
    
    @ViewBuilder
    private func listScrollView(in geometry: GeometryProxy) -> some View {
        let scroll = ScrollView {
            content()
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.bottom, Spacing.tabbedScrollBottomInset)
                .frame(
                    maxWidth: .infinity,
                    minHeight: listMinHeight(in: geometry),
                    alignment: .topLeading
                )
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .plotDismissTextInputWhenTappingOutside(isFocused: $isSearchFocused)
        
        if let onRefresh {
            scroll.refreshable { await onRefresh() }
        } else {
            scroll
        }
    }
    
    private func listMinHeight(in geometry: GeometryProxy) -> CGFloat {
        let pinnedBlock = Spacing.lg
            + PlotChatComposerMetrics.clearButtonHitSize
            + Spacing.lg
        return max(0, geometry.size.height - pinnedBlock)
    }
}
