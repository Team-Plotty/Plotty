import SwiftUI

// MARK: - メモ / TODO / カレンダー用の「＋」新規ボタン
/// タブバー最下端を基準に、その上へ `Spacing.floatingAddGapAboveTabBar` だけ離して表示。
struct PlotFloatingAddButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var accessibilityLabel: String = "新規作成"
    let action: () -> Void
    
    private let diameter: CGFloat = 56
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: diameter, height: diameter)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}
