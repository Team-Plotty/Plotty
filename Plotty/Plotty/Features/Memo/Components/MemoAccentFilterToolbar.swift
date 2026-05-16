import SwiftUI

// MARK: - メモ一覧用ツールバー（色で絞り込み）
struct MemoAccentFilterToolbar: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedAccents: Set<AccentSwatch>
    var resolvedColorScheme: ColorScheme? = nil
    
    private var scheme: ColorScheme {
        resolvedColorScheme ?? colorScheme
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                PlotFilterChip(title: "すべて", isSelected: selectedAccents.isEmpty) {
                    withAnimation(.quick) {
                        selectedAccents.removeAll()
                    }
                }
                .accessibilityLabel("すべての色を表示")
                
                ForEach(AccentSwatch.allCases) { swatch in
                    accentToggle(swatch)
                }
            }
        }
        .id(scheme)
    }
    
    private func accentToggle(_ swatch: AccentSwatch) -> some View {
        let on = selectedAccents.contains(swatch)
        let borderColor: Color = on ? Color.accentColor : (scheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.12))
        let borderWidth: CGFloat = on ? 2.5 : 1
        let shadowRadius: CGFloat = on ? 0 : 2
        
        return Button {
            withAnimation(.quick) {
                if on {
                    selectedAccents.remove(swatch)
                } else {
                    selectedAccents.insert(swatch)
                }
            }
        } label: {
            Circle()
                .fill(swatch.color)
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: .black.opacity(0.12), radius: shadowRadius, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(swatch.title)で絞り込み")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
