import SwiftUI

// MARK: - フィルタチップの寸法（選択・未選択・画面間で共通。HIG 最小タップ 44pt）
enum PlotFilterChipMetrics {
    static let minHeight: CGFloat = Spacing.minTouchTarget
    static let horizontalPadding: CGFloat = Spacing.md
    static let verticalPadding: CGFloat = Spacing.xs
}

// MARK: - フィルタチップの色（薄い灰 → ホバーで少し明るい灰 → 選択で一段明るい灰）
enum PlotFilterChipStyle {
    /// 初期（未選択）
    static func restingFill(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#FFFCF8").opacity(0.10)
            : Color(hex: "#D6D2CA")
    }
    
    /// ホバー（HIG: 初期よりわずかに明るい程度。強いハイライトは使わない）
    static func hoverFill(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#FFFCF8").opacity(0.14)
            : Color(hex: "#E2DED6")
    }
    
    /// 選択
    static func selectedFill(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#FFFCF8").opacity(0.22)
            : Color(hex: "#EEEBE3")
    }
    
    static func fill(isSelected: Bool, isHovered: Bool, colorScheme: ColorScheme) -> Color {
        if isSelected { return selectedFill(colorScheme: colorScheme) }
        if isHovered { return hoverFill(colorScheme: colorScheme) }
        return restingFill(colorScheme: colorScheme)
    }
    
    static func labelColor(isSelected: Bool, colorScheme: ColorScheme) -> Color {
        if isSelected {
            return colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
        }
        return colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

// MARK: - 押下フィードバック（サイズは変えず不透明度のみ）
struct PlotFilterChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - フィルタチップ
struct PlotFilterChip: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.scaledCaption())
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(PlotFilterChipStyle.labelColor(isSelected: isSelected, colorScheme: colorScheme))
                .padding(.horizontal, PlotFilterChipMetrics.horizontalPadding)
                .padding(.vertical, PlotFilterChipMetrics.verticalPadding)
                .frame(minHeight: PlotFilterChipMetrics.minHeight)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            PlotFilterChipStyle.fill(
                                isSelected: isSelected,
                                isHovered: isHovered,
                                colorScheme: colorScheme
                            )
                        )
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PlotFilterChipButtonStyle())
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.16), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

#Preview("フィルタチップ") {
    HStack(spacing: Spacing.sm) {
        PlotFilterChip(title: "すべて", isSelected: true, action: {})
        PlotFilterChip(title: "低", isSelected: false, action: {})
        PlotFilterChip(title: "中", isSelected: false, action: {})
    }
    .padding()
    .background(AmbientBackground())
    .preferredColorScheme(.dark)
}
