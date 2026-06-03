import SwiftUI

// MARK: - メモ / TODO / カレンダー用の「＋」新規ボタン
/// タブバー最下端を基準に、その上へ `Spacing.floatingAddGapAboveTabBar` だけ離して表示。
struct PlotFloatingAddButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var accessibilityLabel: String = "新規作成"
    let action: () -> Void
    
    /// ボタンの視覚的なサイズ（iOS 26 Liquid Glass 推奨サイズ）
    private let visualDiameter: CGFloat = 64
    /// 当たり判定のサイズ（端までタップ可能に）
    private let hitDiameter: CGFloat = 72
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.clear)
                .frame(width: hitDiameter, height: hitDiameter)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: visualDiameter, height: visualDiameter)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
