import SwiftUI

// MARK: - メモ / TODO 用のフローティング検索ボタン
/// 作成ボタン（FAB）の対照位置（左下）に配置。タップで検索欄を展開。
struct PlotFloatingSearchButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var accessibilityLabel: String = "検索"
    let action: () -> Void
    
    /// ボタンの視覚的なサイズ（追加ボタンと同じ）
    private let visualDiameter: CGFloat = 64
    /// 当たり判定のサイズ（追加ボタンと同じ）
    private let hitDiameter: CGFloat = 72
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.clear)
                .frame(width: hitDiameter, height: hitDiameter)
                .overlay {
                    Image(systemName: "magnifyingglass")
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
