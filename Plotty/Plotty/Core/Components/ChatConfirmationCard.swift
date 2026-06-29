import SwiftUI

// MARK: - AI 登録確認カード
struct ChatRegistrationSummary: Identifiable {
    let id = UUID()
    var category: PlotChatCategory
    var title: String
    var detail: String
    var linkedEntityID: UUID?
    var sourceBody: String
    /// 再分類の期限判定に使う元ユーザーメッセージの作成日時
    var sourceMessageCreatedAt: Date?
}

struct ChatConfirmationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let summary: ChatRegistrationSummary
    var isReclassifying: Bool = false
    var onReclassify: ((PlotChatCategory) -> Void)?
    var reclassifyDisabledReason: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: summary.category.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("登録しました")
                        .font(.scaledCaption().weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    Text(summary.title)
                        .font(.scaledBodyLarge().weight(.semibold))
                        .foregroundStyle(primaryColor)
                    
                    Text(summary.detail)
                        .font(.scaledCaption())
                        .foregroundStyle(secondaryColor)
                    
                    Text(summary.category.label)
                        .font(.scaledCaption().weight(.medium))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )
                }
                
                Spacer(minLength: 0)
            }
            
            if onReclassify != nil {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("カテゴリを変更")
                        .font(.scaledCaption().weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        ForEach(PlotChatCategory.reclassifyButtonOrder) { category in
                            PlotCategoryChoiceCard(
                                category: category,
                                isSelected: summary.category == category
                            ) {
                                guard !isReclassifying else { return }
                                onReclassify?(category)
                            }
                            .allowsHitTesting(!isReclassifying)
                            .opacity(isReclassifying && summary.category != category ? 0.55 : 1)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
            } else if let reclassifyDisabledReason {
                Text(reclassifyDisabledReason)
                    .font(.scaledCaption())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(reclassifyDisabledReason)
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.category.label)を登録、\(summary.title)")
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}
