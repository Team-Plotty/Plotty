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
                         ? Color.white.opacity(0.62)
                         : Color.black.opacity(0.55))
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.10)
                      : Color.black.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(colorScheme == .dark
                                      ? Color.white.opacity(0.16)
                                      : Color.black.opacity(0.10), lineWidth: 0.5)
                )
        )
        .onTapGesture {
            onTap?()
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
                         ? Color.white.opacity(0.62)
                         : Color.black.opacity(0.55))
        .padding(.leading, 9)
        .padding(.trailing, 6)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.10)
                      : Color.black.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(colorScheme == .dark
                                      ? Color.white.opacity(0.16)
                                      : Color.black.opacity(0.10), lineWidth: 0.5)
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
        return colorScheme == .dark ? Color.white.opacity(0.62) : Color.black.opacity(0.55)
    }
    
    private var capsuleFill: Color {
        if isSelected {
            return colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
        }
        return colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }
    
    private var capsuleStroke: Color {
        if isSelected { return Color.clear }
        return colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.10)
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.micro)
                .foregroundColor(labelColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(capsuleFill)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(capsuleStroke, lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.quick, value: isSelected)
    }
}

// MARK: - Preview
#Preview("Chips") {
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
    .padding(24)
    .background(Color(hex: "#0F0E0D"))
}
