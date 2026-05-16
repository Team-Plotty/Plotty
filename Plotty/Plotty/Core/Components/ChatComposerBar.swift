import SwiftUI

// MARK: - チャット下部の入力欄
struct ChatComposerBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.connectivity) private var connectivity
    
    @Binding var text: String
    @Binding var selectedCategory: PlotChatCategory?
    @FocusState.Binding var isFocused: Bool
    var onSend: () -> Void
    
    private var hasCategoryChip: Bool {
        selectedCategory != nil
    }
    
    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canSend: Bool {
        connectivity.isOnline && !trimmed.isEmpty
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    private var placeholderColor: Color {
        colorScheme == .dark ? Color.darkInputPlaceholder : Color.lightInputPlaceholder
    }
    
    private var composerMinHeight: CGFloat {
        hasCategoryChip
            ? PlotChatComposerMetrics.minHeightWithChip
            : PlotChatComposerMetrics.minHeightCompact
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if isFocused {
                ChatCategoryQuickActions { category in
                    selectedCategory = category
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            composerField
        }
        .background(Color.clear)
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .animation(.easeOut(duration: 0.2), value: hasCategoryChip)
    }
    
    /// チップ＋入力行を包むフィールド（角丸固定・縦だけ伸縮）
    private var composerField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let category = selectedCategory {
                ChatCategoryInputChip(category: category) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            HStack(alignment: .center, spacing: 12) {
                Button {
                    isFocused = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(secondaryColor)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("登録先を選ぶ")
                
                TextField(
                    "",
                    text: $text,
                    prompt: Text("メッセージ").foregroundStyle(placeholderColor)
                )
                .font(.scaledBodyMedium())
                .foregroundColor(primaryColor)
                .tint(primaryColor)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.send)
                .disabled(!connectivity.isOnline)
                .frame(minHeight: 24)
                .onSubmit {
                    if canSend { send() }
                }
                
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
        }
        .padding(.leading, Spacing.md)
        .padding(.trailing, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: composerMinHeight, alignment: .leading)
        .plotChatComposerGlass()
    }
    
    private func send() {
        guard canSend else { return }
        onSend()
    }
}

#Preview {
    struct Wrapper: View {
        @State private var t = ""
        @State private var cat: PlotChatCategory?
        @FocusState private var focused: Bool
        
        var body: some View {
            VStack {
                Spacer()
                ChatComposerBar(
                    text: $t,
                    selectedCategory: $cat,
                    isFocused: $focused,
                    onSend: {}
                )
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AmbientBackground())
            .environment(\.connectivity, ConnectivityMonitor())
            .onAppear { focused = true }
        }
    }
    return Wrapper()
}
