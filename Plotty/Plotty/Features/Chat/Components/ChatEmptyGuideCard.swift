import SwiftUI

// MARK: - チャット初回ガイド（カード型 empty）
struct ChatEmptyGuideCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Plotty へようこそ", systemImage: "sparkles")
                .font(.scaledBodyLarge().weight(.semibold))
                .foregroundStyle(primaryColor)
            
            Text("自然な言葉で予定・タスク・メモを登録できます。下のチップでカテゴリを選ぶか、そのまま送ってください。")
                .font(.scaledBodyMedium())
                .foregroundStyle(secondaryColor)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                guideRow(icon: "calendar", text: "「明日15時に打ち合わせ」→ 予定")
                guideRow(icon: "checklist", text: "「レポートを金曜までに」→ タスク")
                guideRow(icon: "doc.text", text: "「アイデアをメモ」→ メモ")
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }
    
    private func guideRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.scaledCaption())
                .foregroundStyle(secondaryColor)
        }
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}
