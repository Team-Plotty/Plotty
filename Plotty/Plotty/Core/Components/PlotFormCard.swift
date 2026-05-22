import SwiftUI

// MARK: - シート内のグループ化カード（HIG: 関連項目を1つの面にまとめる）
struct PlotFormCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    
    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let title {
                Text(title)
                    .font(.scaledLabelMedium())
                    .foregroundStyle(.secondary)
                    .padding(.leading, Spacing.xs)
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                content()
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
}

// MARK: - 文字数カウンター（補助ラベル）
struct PlotCharacterCountFooter: View {
    let current: Int
    let maximum: Int
    
    var body: some View {
        Text("\(current) / \(maximum)")
            .font(.scaledCaption())
            .foregroundStyle(current >= maximum ? .red : .secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("文字数 \(current) 文字、上限 \(maximum) 文字")
    }
}
