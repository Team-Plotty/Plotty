import SwiftUI

// MARK: - Chip
struct Chip: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var icon: String? = nil
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.micro)
        }
        .foregroundColor(colorScheme == .dark
                         ? Color.white.opacity(0.72)
                         : Color.black.opacity(0.62))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(chipBackground)
        .onTapGesture {
            onTap?()
        }
    }
    
    private var chipBackground: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
            
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.14), Color.white.opacity(0.06)]
                            : [Color.black.opacity(0.07), Color.black.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.30), Color.white.opacity(0.08)]
                            : [Color.white.opacity(0.6), Color.black.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.6
                )
        }
    }
}

// MARK: - Dismissable Chip
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
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.14), Color.white.opacity(0.06)]
                                    : [Color.black.opacity(0.07), Color.black.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.18)
                                : Color.black.opacity(0.10),
                            lineWidth: 0.6
                        )
                )
        )
    }
}

// MARK: - Selectable Chip
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
                            : [Color(hex: "#1F1A14"), Color(hex: "#0F0E0D")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            ZStack {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.10), Color.white.opacity(0.04)]
                                : [Color.black.opacity(0.05), Color.black.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Capsule(style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.16)
                            : Color.black.opacity(0.08),
                        lineWidth: 0.6
                    )
            }
        }
    }
}

#Preview {
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
