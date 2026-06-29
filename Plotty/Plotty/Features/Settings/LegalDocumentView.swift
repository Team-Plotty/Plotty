import SwiftUI

// MARK: - 利用規約・プライバシーポリシー
enum LegalDocumentKind: String, Identifiable {
    case termsOfService
    case privacyPolicy
    
    var id: String { rawValue }
    
    var navigationTitle: String {
        switch self {
        case .termsOfService: return "利用規約"
        case .privacyPolicy: return "プライバシーポリシー"
        }
    }
    
    var lastUpdated: String { "2026年5月1日" }
}

struct LegalDocumentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let kind: LegalDocumentKind
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("最終更新: \(kind.lastUpdated)")
                    .font(.scaledCaption())
                    .foregroundStyle(secondaryColor)
                
                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(section.title)
                            .font(.scaledBodyLarge().weight(.semibold))
                            .foregroundStyle(primaryColor)
                        Text(section.body)
                            .font(.scaledBodySmall())
                            .foregroundStyle(secondaryColor)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(kind.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
        .onAppear {
            PlotAnalytics.trackScreen(kind == .termsOfService ? .terms : .privacy)
        }
    }
    
    private var sections: [(title: String, body: String)] {
        switch kind {
        case .termsOfService:
            return [
                ("第1条（適用）", "本規約は、Plotty（以下「本サービス」）の利用条件を定めるものです。"),
                ("第2条（利用登録）", "ユーザーは、Google・Apple・メールのいずれかの方法で登録できます。"),
                ("第3条（禁止事項）", "法令違反、他者の権利侵害、本サービスの運営を妨害する行為を禁止します。"),
                ("第4条（免責）", "本サービスは現状有姿で提供されます。運営者は損害について責任を負いません。"),
            ]
        case .privacyPolicy:
            return [
                ("収集するデータ", "アカウント情報、チャット内容、作成した予定・タスク・メモです。"),
                ("利用目的", "サービス提供、AI による分類、品質改善のため利用します。"),
                ("保存期間", "チャットメッセージは作成から30日で削除します。予定・タスク・メモはアカウント削除まで保持します。"),
                ("第三者提供", "法令に基づく場合を除き、同意なく第三者に提供しません。"),
                ("お問い合わせ", "support@plotty.app までご連絡ください。"),
            ]
        }
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(kind: .termsOfService)
            .ambientBackground()
    }
}
