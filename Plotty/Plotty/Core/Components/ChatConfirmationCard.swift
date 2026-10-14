import SwiftUI

// MARK: - AI 登録確認カード
struct ChatRegistrationSummary: Identifiable {
    let id = UUID()
    var category: PlotChatCategory
    var title: String
    var detail: String
    /// 登録したメモ・タスク・予定の ID。カードをタップしたときの遷移先
    var linkedEntityID: UUID?
    
    var route: PlotEntityRoute? {
        linkedEntityID.map { PlotEntityRoute(category: category, id: $0) }
    }
}

struct ChatConfirmationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let summary: ChatRegistrationSummary
    var onOpen: (() -> Void)?
    
    var body: some View {
        Button {
            onOpen?()
        } label: {
            content
        }
        .buttonStyle(PlotChipPressButtonStyle())
        .disabled(onOpen == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.category.label)を登録、\(summary.title)")
        .accessibilityHint(onOpen == nil ? "" : "タップして編集を開く")
    }
    
    private var content: some View {
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
                    .multilineTextAlignment(.leading)
                
                Text(summary.detail)
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                    .multilineTextAlignment(.leading)
                
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
            
            if onOpen != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxHeight: .infinity)
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}
