import SwiftUI

// MARK: - Floating Input Bar
struct FloatingInputBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    @Binding var text: String
    @Binding var sendButtonState: SendButtonState
    var placeholder: String = "メッセージを入力..."
    var onSend: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.scaledBodyLarge())
                .foregroundColor(colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary)
                .focused($isFocused)
                .lineLimit(1...5)
                .onChange(of: text) { _, newValue in
                    withAnimation(.quick) {
                        sendButtonState = newValue.isEmpty ? .empty : .ready
                    }
                }
            
            SendButton(state: $sendButtonState, action: onSend)
        }
        .padding(.leading, Spacing.md)
        .padding(.trailing, Spacing.xs)
        .padding(.vertical, Spacing.xs)
        .frame(minHeight: 52)
        .background(
            PremiumGlass(
                shape: Capsule(style: .continuous),
                glassType: .input
            )
        )
        .overlay(
            // Focus ring
            Capsule(style: .continuous)
                .stroke(
                    isFocused
                        ? (colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.10))
                        : .clear,
                    lineWidth: 0.8
                )
                .animation(.quick, value: isFocused)
        )
    }
}

#Preview {
    struct Preview: View {
        @State var text = ""
        @State var state: SendButtonState = .empty
        var body: some View {
            VStack {
                Spacer()
                FloatingInputBar(text: $text, sendButtonState: $state, onSend: {})
                    .padding(.horizontal, 12)
                    .padding(.bottom, 60)
            }
            .background(AmbientBackground())
        }
    }
    return Preview()
        .preferredColorScheme(.dark)
}
