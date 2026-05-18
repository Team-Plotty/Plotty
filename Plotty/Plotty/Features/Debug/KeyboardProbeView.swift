import SwiftUI

// MARK: - キーボード切り分け（TextField のみ・inset / タブバー / ガラスなし）
struct KeyboardProbeView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("キーボード切り分け")
                .font(.headline)
            
            Text("起動 0.5 秒後に自動フォーカス。出ない場合はシミュレータで ⌘K、または I/O → Keyboard → Connect Hardware Keyboard のチェックを外す。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("ここに入力", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, Spacing.screenEdge)
                .focused($isFocused)
            
            Text(isFocused ? "フォーカス: ON" : "フォーカス: OFF")
                .font(.caption.monospaced())
            
            Spacer()
        }
        .padding(.top, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    KeyboardProbeView()
}
