import SwiftUI

// MARK: - メモ空状態
struct MemoEmptyState: View {
    let isCompletelyEmpty: Bool
    let hint: String
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            if isCompletelyEmpty {
                Text("メモがありません")
                    .font(.scaledBodyLarge())
                    .foregroundStyle(.secondary)
                Text("右下の＋から新しいメモを作成")
                    .font(.scaledBodySmall())
                    .foregroundStyle(.tertiary)
            } else {
                Text("該当するメモがありません")
                    .font(.scaledBodyLarge())
                    .foregroundStyle(.secondary)
                Text(hint)
                    .font(.scaledBodySmall())
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}
