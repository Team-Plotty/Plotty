import SwiftUI

// MARK: - ガラス面アイコンボタン（一覧カード角丸 / 円形）
struct PlotGlassCardIconButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    enum ShapeStyle {
        case card(cornerRadius: CGFloat = Radius.md)
        case circle
    }
    
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void
    
    var shape: ShapeStyle = .card()
    var size: CGFloat = Spacing.minTouchTarget
    var iconSize: CGFloat = 16
    
    var body: some View {
        switch shape {
        case .circle:
            circleGlassButton
        case .card(let cornerRadius):
            cardGlassButton(cornerRadius: cornerRadius)
        }
    }
    
    /// ＋ FAB と同じ：円形ガラス＋`.interactive()` のみ（押下で四角く潰れない）
    private var circleGlassButton: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(accessibilityLabel)
    }
    
    private func cardGlassButton(cornerRadius: CGFloat) -> some View {
        let mask = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: size, height: size)
                .contentShape(mask)
        }
        .buttonStyle(PlotChipPressButtonStyle())
        .glassEffect(.regular.interactive(), in: mask)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        PlotGlassCardIconButton(systemName: "xmark", accessibilityLabel: "閉じる", action: {}, shape: .circle)
        PlotGlassCardIconButton(systemName: "xmark", accessibilityLabel: "閉じる", action: {})
    }
    .padding()
    .ambientBackground()
    .preferredColorScheme(.dark)
}
