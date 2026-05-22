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
