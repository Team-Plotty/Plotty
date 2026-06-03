import SwiftUI

// MARK: - iOS 26 Liquid Glass 検索バー
/// iOS 26 の Liquid Glass デザインに準拠した検索バー
struct PlotFloatingSearchField: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var placeholder: String = "検索"
    var onCancel: (() -> Void)?
    
    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // 検索バー本体（Liquid Glass）
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(secondaryColor)
                
                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder).foregroundStyle(secondaryColor)
                )
                .font(.body)
                .foregroundColor(textColor)
                .tint(textColor)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.search)
                
                // クリアボタン
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(secondaryColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 44)
            .glassEffect(.regular.interactive(), in: Capsule())
            
            // 閉じるボタン（×）- チャット入力欄と同じスタイル
            if let onCancel {
                PlotGlassCardIconButton(
                    systemName: "xmark",
                    accessibilityLabel: "検索を閉じる",
                    action: {
                        text = ""
                        isFocused = false
                        onCancel()
                    },
                    shape: .circle,
                    size: 44
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: onCancel != nil)
    }
}
