import SwiftUI

// MARK: - メモ一覧用フィルタ（「すべて」＋ 色カラーチップで絞り込み）
struct MemoAccentFilterToolbar: View {
    @Binding var selectedAccents: Set<AccentSwatch>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                PlotHIGBorderedButton("すべて", isSelected: selectedAccents.isEmpty) {
                    withAnimation(.quick) {
                        selectedAccents.removeAll()
                    }
                }
                .accessibilityLabel("すべての色を表示")
                
                ForEach(AccentSwatch.allCases) { swatch in
                    PlotAccentSwatchButton(
                        swatch: swatch,
                        isSelected: selectedAccents.contains(swatch)
                    ) {
                        withAnimation(.quick) {
                            if selectedAccents.contains(swatch) {
                                selectedAccents.remove(swatch)
                            } else {
                                selectedAccents.insert(swatch)
                            }
                        }
                    }
                }
            }
        }
    }
}
