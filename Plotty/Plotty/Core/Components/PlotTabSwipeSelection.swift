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

// MARK: - フッタータブの横ページャー（ドラッグ中も画面が指についてスライド）
struct PlotTabPager<Content: View>: View {
    @Binding var selectedTab: TabItem
    @ViewBuilder var content: (TabItem) -> Content

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

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width

            HStack(alignment: .top, spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    content(tab)
                        .frame(width: pageWidth, height: geometry.size.height, alignment: .top)
                }
            }
            .offset(x: pageOffset(pageWidth: pageWidth))
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
        .animation(pageAnimation, value: selectedTab)
    }
    
    /// スライド中も含め、チャットページが画面中央付近にあるときだけ入力ドックを出す。
    private func isChatPageVisible(pageWidth: CGFloat) -> Bool {
        guard pageWidth > 0 else { return selectedTab == .chat }
        let chatIndex = CGFloat(TabItem.chat.rawValue)
        let visualIndex = CGFloat(selectedTab.rawValue) - dragOffset / pageWidth
        return abs(visualIndex - chatIndex) < 0.5
    }

    private func pageOffset(pageWidth: CGFloat) -> CGFloat {
        let base = -CGFloat(selectedTab.rawValue) * pageWidth
        let live = dragAxis == .horizontal ? dragOffset : 0
        return base + rubberBandedDrag(live, pageWidth: pageWidth)
    }

    private func rubberBandedDrag(_ offset: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let maxIndex = TabItem.allCases.count - 1
        var adjusted = offset
        if selectedTab.rawValue == 0, adjusted > 0 {
            adjusted = min(adjusted * 0.35, pageWidth * 0.35)
        }
        if selectedTab.rawValue == maxIndex, adjusted < 0 {
            adjusted = max(adjusted * 0.35, -pageWidth * 0.35)
        }
        return adjusted
    }

    private func pagingGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .onChanged { value in
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
                defer {
                    dragAxis = .undecided
                    dragOffset = 0
                }

                guard dragAxis == .horizontal else { return }

                let dx = value.translation.width
                let predicted = value.predictedEndTranslation.width

                var targetIndex = selectedTab.rawValue
                let snapDistance = pageWidth * snapRatio
                let flickDistance = pageWidth * 0.42

                if dx < -snapDistance || predicted < -flickDistance {
                    targetIndex += 1
                } else if dx > snapDistance || predicted > flickDistance {
                    targetIndex -= 1
                }

                let clamped = min(max(targetIndex, 0), TabItem.allCases.count - 1)
                guard let target = TabItem(rawValue: clamped) else { return }
                guard target != selectedTab else { return }

                if selectedTab == .chat || target != .chat {
                    PlotTextInputDismiss.postNotification()
                }

                withAnimation(pageAnimation) {
                    selectedTab = target
                }
            }
    }
}
