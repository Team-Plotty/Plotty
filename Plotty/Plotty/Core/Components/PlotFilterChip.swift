import SwiftUI

// MARK: - フィルタチップの寸法（選択・未選択・画面間で共通。HIG 最小タップ 44pt）
enum PlotFilterChipMetrics {
    static let minHeight: CGFloat = Spacing.minTouchTarget
    static let horizontalPadding: CGFloat = Spacing.md
    static let verticalPadding: CGFloat = Spacing.xs
}

// MARK: - フィルタチップ（Liquid Glass・`Chip` と同系）
struct PlotFilterChip: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.scaledCaption())
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(labelColor)
                .padding(.horizontal, PlotFilterChipMetrics.horizontalPadding)
                .padding(.vertical, PlotFilterChipMetrics.verticalPadding)
                .frame(minHeight: PlotFilterChipMetrics.minHeight)
                .plotChipGlassCapsule()
                .overlay {
                    if isSelected {
                        Capsule(style: .continuous)
                            .strokeBorder(PlotColors.selectedBorder(plotColorScheme), lineWidth: 1)
                    }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PlotChipPressButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.16), value: isSelected)
    }
    
    private var labelColor: Color {
        if isSelected {
            return PlotColors.textPrimary(plotColorScheme)
        }
        return PlotColors.textSecondary(plotColorScheme)
    }
}

// MARK: - アクセント色カラーチップ（メモの色フィルタなど）
struct PlotAccentSwatchButton: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    let swatch: AccentSwatch
    let isSelected: Bool
    var diameter: CGFloat = Spacing.minTouchTarget
    var dotDiameter: CGFloat = 28
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(swatch.color)
                .frame(width: dotDiameter, height: dotDiameter)
                .frame(width: diameter, height: diameter)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(PlotColors.selectedBorder(plotColorScheme), lineWidth: 2.5)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(PlotChipPressButtonStyle())
        .accessibilityLabel("\(swatch.title)で絞り込み")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.16), value: isSelected)
    }
}

#Preview("フィルタ・ダーク") {
    PlotFilterToolbarPreview()
        .preferredColorScheme(.dark)
        .environment(\.plotColorScheme, .dark)
}

#Preview("フィルタ・ライト") {
    PlotFilterToolbarPreview()
        .preferredColorScheme(.light)
        .environment(\.plotColorScheme, .light)
}

private struct PlotFilterToolbarPreview: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            PlotFilterChip(title: "すべて", isSelected: true, action: {})
            PlotAccentSwatchButton(swatch: .sage, isSelected: false, action: {})
            PlotAccentSwatchButton(swatch: .sky, isSelected: true, action: {})
        }
        .padding()
        .background(AmbientBackground())
    }
}
