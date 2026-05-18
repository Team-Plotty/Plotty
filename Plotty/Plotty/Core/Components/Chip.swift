import SwiftUI

// MARK: - チップの文字色コンテキスト
enum ChipTextStyle {
    /// 通常（AI 吹き出し下・一覧など）
    case standard
    /// ユーザー送信吹き出し内
    case onUserBubble
}

// MARK: - チップ（短文ラベル。チャット内のタグなど）
struct Chip: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
    var text: String
    var icon: String? = nil
    var onTap: (() -> Void)? = nil
    /// `glassEffect` 内で環境がずれる場合の上書き（未指定時は `plotColorScheme`）
    var resolvedColorScheme: ColorScheme? = nil
    var glassStyle: PlotChipGlassStyle = .standalone
    var textStyle: ChipTextStyle = .standard
    
    private var scheme: ColorScheme {
        resolvedColorScheme ?? plotColorScheme
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
        .symbolRenderingMode(.monochrome)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .plotChipGlassCapsule(style: glassStyle)
    }
    
    private var labelColor: Color {
        switch textStyle {
        case .standard:
            return PlotColors.textPrimary(scheme)
        case .onUserBubble:
            return PlotColors.textUser(scheme)
        }
    }
}

// MARK: - 閉じる付きチップ
struct DismissableChip: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    
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
        .foregroundStyle(PlotColors.textPrimary(plotColorScheme))
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
    }
    .padding(40)
    .background(AmbientBackground())
    .environment(\.plotColorScheme, .dark)
    .preferredColorScheme(.dark)
}
