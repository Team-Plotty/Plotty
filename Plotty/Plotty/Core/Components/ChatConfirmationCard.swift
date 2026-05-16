import SwiftUI

// MARK: - AI 登録確認カード
struct ChatRegistrationSummary: Identifiable {
    let id = UUID()
    let category: PlotChatCategory
    let title: String
    let detail: String
}

struct ChatConfirmationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let summary: ChatRegistrationSummary
    
    var body: some View {
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
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
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
