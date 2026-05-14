import SwiftUI

// MARK: - チップ（短文ラベル。チャット内のタグなど）
struct Chip: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var icon: String? = nil
    var onTap: (() -> Void)? = nil
    /// `glassEffect` の内側などで `@Environment(\.colorScheme)` が誤ることがあるため、親から正しい外観を渡せるようにする。
    var resolvedColorScheme: ColorScheme? = nil
    
    private var scheme: ColorScheme {
        resolvedColorScheme ?? colorScheme
    }
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.micro)
        }
        .foregroundColor(scheme == .dark
                         ? Color.white.opacity(0.72)
                         : Color.black.opacity(0.62))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(chipBackground)
        .onTapGesture {
            onTap?()
        }
    }
    
    @ViewBuilder
    private var chipBackground: some View {
        /// 吹き出しなど `glassEffect` の内側ではネストしたガラスが暗く潰れやすいので、ライトはフラット寄りにする。
        if scheme == .dark {
            Capsule(style: .continuous)
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.07))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
                )
        }
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
                .font(.micro)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .foregroundColor(colorScheme == .dark
                         ? Color.white.opacity(0.72)
                         : Color.black.opacity(0.62))
        .padding(.leading, 10)
        .padding(.trailing, 7)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .glassEffect(.regular.interactive(), in: .capsule)
        )
    }
}

// MARK: - 選択状態の切り替えができるチップ
struct SelectableChip: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var isSelected: Bool
    var onTap: () -> Void
    
    private var labelColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.darkBase : Color.lightBase
        }
        return colorScheme == .dark ? Color.white.opacity(0.72) : Color.black.opacity(0.62)
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.micro)
                .foregroundColor(labelColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(background)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.quick, value: isSelected)
    }
    
    @ViewBuilder
    private var background: some View {
        if isSelected {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(hex: "#FFFCF8"), Color(hex: "#E8E4DD")]
                            : [Color(hex: "#2E2418"), Color(hex: "#38342F")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            Capsule(style: .continuous)
                .glassEffect(.regular.interactive(), in: .capsule)
        }
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
            SelectableChip(text: "すべて", isSelected: true, onTap: {})
            SelectableChip(text: "今日", isSelected: false, onTap: {})
            SelectableChip(text: "今週", isSelected: false, onTap: {})
        }
    }
    .padding(40)
    .background(AmbientBackground())
    .preferredColorScheme(.dark)
}
