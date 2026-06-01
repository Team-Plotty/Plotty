import SwiftUI

extension View {
    /// 右上の吹き出しから右スライドの作成／編集パネルを開く。
    func plottySideSlideEditor<Editor: View>(
        isPresented: Binding<Bool>,
        showsBubbleTrigger: Bool = true,
        bubbleTitle: String = "作成",
        bubbleSystemImage: String = "square.and.pencil",
        panelIdealWidthFraction: CGFloat = 0.92,
        panelMaxWidth: CGFloat = 420,
        @ViewBuilder editor: @escaping () -> Editor
    ) -> some View {
        modifier(
            SideSlideEditorLayoutModifier(
                isPresented: isPresented,
                showsBubbleTrigger: showsBubbleTrigger,
                bubbleTitle: bubbleTitle,
                bubbleSystemImage: bubbleSystemImage,
                panelIdealWidthFraction: panelIdealWidthFraction,
                panelMaxWidth: panelMaxWidth,
                editor: editor
            )
        )
    }
}

// MARK: - 右スライド編集パネル

private struct SideSlideEditorLayoutModifier<Editor: View>: ViewModifier {
    @Binding var isPresented: Bool
    let showsBubbleTrigger: Bool
    let bubbleTitle: String
    let bubbleSystemImage: String
    let panelIdealWidthFraction: CGFloat
    let panelMaxWidth: CGFloat
    let editor: () -> Editor

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if showsBubbleTrigger, !isPresented {
                    SpeechBubbleEditorTrigger(
                        title: bubbleTitle,
                        systemImage: bubbleSystemImage,
                        action: openPanel
                    )
                    .padding(Spacing.md)
                }
            }
            .overlay {
                if isPresented {
                    GeometryReader { geometry in
                        ZStack(alignment: .trailing) {
                            Color.black.opacity(0.35)
                                .ignoresSafeArea()
                                .onTapGesture(perform: closePanel)

                            editor()
                                .frame(
                                    idealWidth: nil,
                                    maxWidth: panelWidth(for: geometry.size.width),
                                    maxHeight: .infinity,
                                    alignment: .top
                                )
                                .background(.regularMaterial)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: Radius.lg,
                                        bottomLeadingRadius: Radius.lg,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: 0
                                    )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 16, x: -4, y: 0)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
            }
            .animation(panelAnimation, value: isPresented)
    }

    private func panelWidth(for containerWidth: CGFloat) -> CGFloat {
        min(containerWidth * panelIdealWidthFraction, panelMaxWidth)
    }

    private var panelAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.28)
    }

    private func openPanel() {
        if reduceMotion {
            isPresented = true
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                isPresented = true
            }
        }
    }

    private func closePanel() {
        if reduceMotion {
            isPresented = false
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                isPresented = false
            }
        }
    }
}
