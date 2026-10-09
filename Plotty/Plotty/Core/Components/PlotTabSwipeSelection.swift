import SwiftUI

// MARK: - 横ページング中は縦スクロールを止める（Environment）
private struct PlotTabHorizontalPagingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var plotTabHorizontalPaging: Bool {
        get { self[PlotTabHorizontalPagingKey.self] }
        set { self[PlotTabHorizontalPagingKey.self] = newValue }
    }
}

// MARK: - チャット入力ドックの表示（横スワイプ中はチャットページが画面外なら非表示）
struct PlotChatComposerVisiblePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = true
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

// MARK: - フッタータブのページャー
/// タップ（プログラムからの変更を含む）ではクロスディゾルブ、横スワイプでは指に追従するスライドで切り替える。
/// 各ページは常に生かしておき、スクロール位置や入力中の状態を切り替えで失わないようにしている。
struct PlotTabPager<Content: View>: View {
    @Binding var selectedTab: TabItem
    @ViewBuilder var content: (TabItem) -> Content

    /// 実際に前面に出しているタブ。`selectedTab` がタップで先に変わり、フェードの完了後に追いつく。
    @State private var displayedTab: TabItem
    /// クロスディゾルブ中は全ページを同じ位置に重ね、透過だけで入れ替える。
    @State private var isDissolving = false
    /// 連続タップ時、古いフェードの完了処理が新しいフェードを途中で打ち切らないための世代番号。
    @State private var dissolveGeneration = 0
    @State private var dragOffset: CGFloat = 0
    @State private var dragAxis: DragAxis = .undecided

    private let snapRatio: CGFloat = 0.22
    private let axisLockDistance: CGFloat = 14
    private let pageAnimation = Animation.easeInOut(duration: 0.32)

    private enum DragAxis {
        case undecided
        case horizontal
        case vertical
    }

    init(selectedTab: Binding<TabItem>, @ViewBuilder content: @escaping (TabItem) -> Content) {
        _selectedTab = selectedTab
        self.content = content
        _displayedTab = State(initialValue: selectedTab.wrappedValue)
    }

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width

            ZStack(alignment: .topLeading) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    let isHiddenByDissolve = isDissolving && tab != displayedTab

                    content(tab)
                        .frame(width: pageWidth, height: geometry.size.height, alignment: .top)
                        .offset(x: pageOffset(for: tab, pageWidth: pageWidth))
                        .opacity(isHiddenByDissolve ? 0 : 1)
                        .allowsHitTesting(!isHiddenByDissolve)
                        .accessibilityHidden(isHiddenByDissolve)
                }
            }
            .frame(width: pageWidth, height: geometry.size.height, alignment: .topLeading)
            .transaction { transaction in
                if dragAxis == .horizontal {
                    transaction.animation = nil
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(pagingGesture(pageWidth: pageWidth))
            .background {
                Color.clear.preference(
                    key: PlotChatComposerVisiblePreferenceKey.self,
                    value: isChatPageVisible(pageWidth: pageWidth)
                )
            }
        }
        .clipped()
        .environment(\.plotTabHorizontalPaging, dragAxis == .horizontal)
        .onChange(of: selectedTab) { _, newTab in
            guard newTab != displayedTab else { return }
            crossDissolve(to: newTab)
        }
    }

    /// 1. アニメなしで全ページを重ねる（新ページは透明のまま中央へ）
    /// 2. 次の描画サイクルで前面のタブを入れ替え、透過をアニメーションさせる
    /// 3. 完了後にアニメなしでスライド用の配置へ戻す（前面ページは位置 0 のままなので見た目は変わらない）
    private func crossDissolve(to newTab: TabItem) {
        dissolveGeneration += 1
        let generation = dissolveGeneration

        withoutAnimation { isDissolving = true }
        DispatchQueue.main.async {
            withAnimation(.crossDissolve) {
                displayedTab = newTab
            } completion: {
                guard generation == dissolveGeneration else { return }
                withoutAnimation { isDissolving = false }
            }
        }
    }

    private func withoutAnimation(_ body: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
    }
    
    /// スライド中も含め、チャットページが画面中央付近にあるときだけ入力ドックを出す。
    private func isChatPageVisible(pageWidth: CGFloat) -> Bool {
        guard pageWidth > 0, !isDissolving else { return displayedTab == .chat }
        let chatIndex = CGFloat(TabItem.chat.rawValue)
        let visualIndex = CGFloat(displayedTab.rawValue) - dragOffset / pageWidth
        return abs(visualIndex - chatIndex) < 0.5
    }

    private func pageOffset(for tab: TabItem, pageWidth: CGFloat) -> CGFloat {
        guard !isDissolving else { return 0 }
        let base = CGFloat(tab.rawValue - displayedTab.rawValue) * pageWidth
        let live = dragAxis == .horizontal ? dragOffset : 0
        return base + rubberBandedDrag(live, pageWidth: pageWidth)
    }

    private func rubberBandedDrag(_ offset: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let maxIndex = TabItem.allCases.count - 1
        var adjusted = offset
        if displayedTab.rawValue == 0, adjusted > 0 {
            adjusted = min(adjusted * 0.35, pageWidth * 0.35)
        }
        if displayedTab.rawValue == maxIndex, adjusted < 0 {
            adjusted = max(adjusted * 0.35, -pageWidth * 0.35)
        }
        return adjusted
    }

    private func pagingGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .onChanged { value in
                guard !isDissolving else { return }
                let dx = value.translation.width
                let dy = value.translation.height

                if dragAxis == .undecided {
                    let absX = abs(dx)
                    let absY = abs(dy)
                    guard max(absX, absY) >= axisLockDistance else { return }
                    if absX > absY {
                        dragAxis = .horizontal
                        PlotTextInputDismiss.postNotification()
                    } else {
                        dragAxis = .vertical
                        return
                    }
                }

                guard dragAxis == .horizontal else { return }
                dragOffset = dx
            }
            .onEnded { value in
                guard dragAxis == .horizontal else {
                    dragAxis = .undecided
                    dragOffset = 0
                    return
                }

                let dx = value.translation.width
                let predicted = value.predictedEndTranslation.width

                var targetIndex = displayedTab.rawValue
                let snapDistance = pageWidth * snapRatio
                let flickDistance = pageWidth * 0.42

                if dx < -snapDistance || predicted < -flickDistance {
                    targetIndex += 1
                } else if dx > snapDistance || predicted > flickDistance {
                    targetIndex -= 1
                }

                let clamped = min(max(targetIndex, 0), TabItem.allCases.count - 1)
                let target = TabItem(rawValue: clamped) ?? displayedTab

                if target != displayedTab, displayedTab == .chat || target != .chat {
                    PlotTextInputDismiss.postNotification()
                }

                // displayedTab も同時に更新し、onChange 側でクロスディゾルブが走らないようにする（スワイプはスライドのまま）。
                // ドラッグ量のリセットも同じアニメーションに含め、指を離した位置から目的のページへ滑らかに収める。
                withAnimation(pageAnimation) {
                    dragAxis = .undecided
                    dragOffset = 0
                    displayedTab = target
                    selectedTab = target
                }
            }
    }
}
