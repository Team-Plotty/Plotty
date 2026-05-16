import SwiftUI

// MARK: - チップ（短文ラベル。チャット内のタグなど）
struct Chip: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var icon: String? = nil
    var onTap: (() -> Void)? = nil
    /// `glassEffect` の内側などで `@Environment(\.colorScheme)` が誤ることがあるため、親から正しい外観を渡せるようにする。
    var resolvedColorScheme: ColorScheme? = nil
    var glassStyle: PlotChipGlassStyle = .standalone
    
    private var scheme: ColorScheme {
        resolvedColorScheme ?? colorScheme
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            chipLabel
        }
        .buttonStyle(PlotChipPressButtonStyle())
        .hoverEffect(.highlight)
        .disabled(onTap == nil)
    }
    
    private var chipLabel: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.scaledCaption().weight(.medium))
        }
        .foregroundStyle(labelColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .plotChipGlassCapsule(style: glassStyle)
    }
    
    private var labelColor: Color {
        scheme == .dark ? Color.white : Color.primary
    }
}

// MARK: - 閉じる付きチップ
struct DismissableChip: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(text)
                .font(.scaledCaption().weight(.medium))
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
        .padding(.leading, Spacing.sm)
        .padding(.trailing, Spacing.xs)
        .frame(minHeight: Spacing.minTouchTarget)
        .plotChipGlassCapsule()
    }
}

#Preview("チップ各種") {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            Chip(text: "10:00 ミーティング")
            Chip(text: "14:00 外出", icon: "calendar")
        }
        HStack(spacing: 8) {
            DismissableChip(text: "フィルター", onDismiss: {})
            DismissableChip(text: "タグ", onDismiss: {})
        }
        HStack(spacing: 8) {
            PlotFilterChip(title: "すべて", isSelected: true, action: {})
            PlotFilterChip(title: "今日", isSelected: false, action: {})
            PlotFilterChip(title: "今週", isSelected: false, action: {})
        }
    }
    .padding(40)
    .background(AmbientBackground())
    .preferredColorScheme(.dark)
}
