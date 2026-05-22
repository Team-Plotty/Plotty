import SwiftUI

// MARK: - メモ / TODO 用・一覧直上の検索行
/// チャット入力と同様、フォーカス時に右外へ円形 ×（Search fields HIG 準拠の角丸）
struct PlotTopSearchRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    
    private var primary: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var placeholder: Color {
        colorScheme == .dark ? Color.darkInputPlaceholder : Color.lightInputPlaceholder
    }
    
    private var expansionAnimation: Animation {
        .easeOut(duration: PlotChatComposerMetrics.expansionDuration)
    }
    
    var body: some View {
        let trailingInset = isFocused
            ? PlotChatComposerMetrics.clearButtonHitSize + PlotChatComposerMetrics.trailingControlSpacing
            : 0
        
        ZStack(alignment: .bottomTrailing) {
            searchFieldBox
                .padding(.trailing, trailingInset)
            
            PlotGlassCardIconButton(
                systemName: "xmark",
                accessibilityLabel: "検索を終了",
                action: dismissSearch,
                shape: .circle,
                size: PlotChatComposerMetrics.clearButtonHitSize
            )
            .opacity(isFocused ? 1 : 0)
            .allowsHitTesting(isFocused)
        }
        .animation(expansionAnimation, value: isFocused)
    }
    
    private var searchFieldBox: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(placeholder)
                .accessibilityHidden(true)
                .frame(width: 28, height: 28, alignment: .center)
            
            TextField(
                "",
                text: $text,
                prompt: Text("検索").foregroundStyle(placeholder)
            )
            .font(.scaledBodyMedium())
            .foregroundColor(primary)
            .tint(primary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textFieldStyle(.plain)
            .focused($isFocused)
            .submitLabel(.search)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .frame(minHeight: PlotChatComposerMetrics.searchFieldHeight)
        .plotChatComposerGlass()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("検索")
    }
    
    private func dismissSearch() {
        withAnimation(expansionAnimation) {
            isFocused = false
        }
    }
}

#Preview {
    struct Wrapper: View {
        @State private var q = ""
        @FocusState private var focused: Bool
        var body: some View {
            PlotTopSearchRow(text: $q, isFocused: $focused)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AmbientBackground())
        }
    }
    return Wrapper()
}
