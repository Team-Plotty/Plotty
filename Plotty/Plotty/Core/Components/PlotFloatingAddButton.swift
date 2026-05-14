import SwiftUI

// MARK: - 右下の「＋」FAB（メモ / TODO / カレンダーで共通）
/// 親画面の `ScrollView` 下に余白を足し、このボタンを `ZStack` の `bottomTrailing` に置く想定。
struct PlotFloatingAddButton: View {
    var accessibilityLabel: String = "新規作成"
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
        }
        .buttonStyle(GlassIconButtonStyle(dimension: 56))
        .accessibilityLabel(accessibilityLabel)
        .zIndex(1000)
    }
}
