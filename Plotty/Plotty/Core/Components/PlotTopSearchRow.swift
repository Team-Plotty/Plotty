import SwiftUI

// MARK: - メモ / TODO 用・一覧直上の検索行
/// スクロール内容の先頭に置く検索欄。ガラスは `plotInputCapsuleGlass`（背景のみ）。
/// `FocusState` は親でタブ切替・空きタップと連動させる。
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
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .plotInputCapsuleGlass()
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

#Preview("ライト") {
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
        .preferredColorScheme(.light)
}
