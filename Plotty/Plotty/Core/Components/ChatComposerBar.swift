import SwiftUI

// MARK: - チャット下部の入力欄
struct ChatComposerBar: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
    @Environment(\.connectivity) private var connectivity
    
    @Binding var text: String
    @Binding var selectedCategory: PlotChatCategory?
    @FocusState.Binding var isFocused: Bool
    var inferenceModel: ChatCategoryInferenceModel?
    var isAIProcessing: Bool = false
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
        PlotColors.textPrimary(plotColorScheme)
    }
    
    private var secondaryColor: Color {
        PlotColors.textSecondary(plotColorScheme)
    }
    
    private var placeholderColor: Color {
        plotColorScheme == .dark ? Color.darkInputPlaceholder : Color.lightInputPlaceholder
    }
    
    private var composerMinHeight: CGFloat {
        hasCategoryChip
            ? PlotChatComposerMetrics.minHeightWithChip
            : PlotChatComposerMetrics.minHeightCompact
    }
    
    private var composerExpansionAnimation: Animation {
        .easeOut(duration: PlotChatComposerMetrics.expansionDuration)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if isFocused {
                ChatCategoryQuickActions { category in
                    selectedCategory = category
                    inferenceModel?.reset()
                }
                .transition(.identity)
            }

            if let suggestion = inferenceModel?.suggestion,
               selectedCategory == nil,
               isFocused {
                ChatCategoryInferenceSuggestion(suggestion: suggestion) {
                    selectedCategory = suggestion.category
                    inferenceModel?.reset()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // 閉じるボタンは置かない。キーボードは入力欄の外（一覧・ヘッダー・タブ）をタップして下げる
            composerField
        }
        // カテゴリ選択・推論ヒント・送信ボタンも入力の一部なので、押してもキーボードを閉じない
        .plotTextInputArea()
        .animation(isFocused ? composerExpansionAnimation : nil, value: isFocused)
        .animation(composerExpansionAnimation, value: inferenceModel?.suggestion)
    }
    
    /// チップ＋入力行を包むフィールド（角丸固定・縦だけ伸縮）
    private var composerField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let category = selectedCategory {
                ChatCategoryInputChip(category: category) {
                    selectedCategory = nil
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.identity)
            }
            
            HStack(alignment: .center, spacing: Spacing.sm) {
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
                .frame(minHeight: 24)
                .onSubmit {
                    if canSend { send() }
                }
                
                sendButton
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        // チップの出し入れで高さをアニメーションさせない。ガラス背景と外側のレイアウトは即座に変わるため、
        // 中身だけ動かすと入力行が遅れて追従し、「メッセージ」がチップに重なったり枠の外へはみ出したりする
        .frame(maxWidth: .infinity, minHeight: composerMinHeight, alignment: .leading)
        .plotChatComposerSurface()
    }
    
    private var sendButton: some View {
        Button {
            send()
        } label: {
            ZStack {
                Circle()
                    .fill(sendFillColor)
                
                if isAIProcessing {
                    CircleBorderChaser(speed: .fast, palette: .aiGlow, lineWidth: 2.5)
                }
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(sendIconColor)
            }
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .disabled(!canSend || isAIProcessing)
        .accessibilityLabel(isAIProcessing ? "AI が応答を作成中" : "送信")
    }
    
    private var sendFillColor: Color {
        if isAIProcessing {
            return primaryColor.opacity(0.85)
        }
        return canSend ? primaryColor : secondaryColor.opacity(0.3)
    }
    
    private var sendIconColor: Color {
        if isAIProcessing {
            return plotColorScheme == .dark ? Color.darkBase : Color.lightBase
        }
        return canSend
            ? (plotColorScheme == .dark ? Color.darkBase : Color.lightBase)
            : secondaryColor.opacity(0.6)
    }
    
    private func send() {
        guard canSend, !isAIProcessing else { return }
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
