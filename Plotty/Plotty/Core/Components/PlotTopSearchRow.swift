import SwiftUI

// MARK: - TODO / カレンダー用・一覧直上の検索行
/// スクロール内容の先頭に置く検索欄。iOS 26 の Liquid Glass（`glassEffect`）とチャット入力欄を揃えた見た目。
/// `FocusState` は親でタブ切替・空きタップと連動させる。
struct PlotTopSearchRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    
    private var primary: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondary: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(secondary)
                .accessibilityHidden(true)
                .frame(width: 28, height: 28, alignment: .center)
            
            TextField("", text: $text, prompt: Text("検索").foregroundStyle(secondary))
                .font(.scaledBodyMedium())
                .foregroundStyle(primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.search)
                .frame(minHeight: 24, alignment: .center)
        }
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("検索")
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
