import SwiftUI

// MARK: - チャット下部の入力欄（iOS 26 Liquid Glass）
/// iOS 26 の `.glassEffect()` を使用。左に＋・中央にテキスト・右に送信ボタン。
struct ChatComposerBar: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var onSend: () -> Void
    
    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canSend: Bool {
        !trimmed.isEmpty
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 左: 追加ボタン
            Button {
                // 添付などは API 接続時に差し替え
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(secondaryColor)
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)
            .accessibilityLabel("追加")
            
            // 中央: テキスト入力
            TextField("", text: $text, prompt: Text("メッセージ").foregroundStyle(secondaryColor), axis: .vertical)
                .font(.scaledBodyMedium())
                .foregroundStyle(primaryColor)
                .multilineTextAlignment(.leading)
                .lineLimit(1...8)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.send)
                .frame(minHeight: 24, alignment: .center)
                .onSubmit {
                    if canSend { send() }
                }
            
            // 右: 送信ボタン
            Button {
                send()
            } label: {
                ZStack {
                    Circle()
                        .fill(canSend ? primaryColor : secondaryColor.opacity(0.3))
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSend
                            ? (colorScheme == .dark ? Color.darkBase : Color.lightBase)
                            : secondaryColor.opacity(0.6))
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("送信")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
    
    private func send() {
        guard canSend else { return }
        onSend()
        isFocused = false
    }
}

#Preview {
    struct Wrapper: View {
        @State private var t = ""
        @FocusState private var focused: Bool
        var body: some View {
            VStack {
                Spacer()
                ChatComposerBar(text: $t, isFocused: $focused, onSend: {})
                    .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AmbientBackground())
        }
    }
    return Wrapper()
        .preferredColorScheme(.dark)
}
