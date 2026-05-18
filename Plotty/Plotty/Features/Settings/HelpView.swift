import SwiftUI

// MARK: - ヘルプ画面
struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var highlightRelay: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if highlightRelay {
                    relaySection
                }
                
                faqSection(
                    title: "認証",
                    items: [
                        ("ログインできない", "Google / Apple / メールのいずれかで再試行してください。Apple の非公開メールの場合は、初回と同じ方法でログインしてください。"),
                        ("アカウントを切り替えたい", "設定 → アカウントを切り替え から選べます。"),
                    ]
                )
                
                faqSection(
                    title: "AI・分類",
                    items: [
                        ("カテゴリを選ぶには", "チャット入力欄の上で「予定」「タスク」「メモ」を選んでから送信できます。"),
                        ("登録結果を確認する", "送信後、チャット内の確認カードで内容を確認できます。"),
                    ]
                )
                
                faqSection(
                    title: "データ",
                    items: [
                        ("チャットはどれくらい残る？", "メッセージは作成から30日で削除されます。予定・タスク・メモは残ります。"),
                        ("オフラインで使える？", "送信や同期にはインターネット接続が必要です。"),
                    ]
                )
                
                troubleshootSection
                
                contactSection
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.vertical, Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("ヘルプ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
    }
    
    private var relaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Apple の非公開メール（Hide My Email）")
                .font(.scaledLabelMedium())
                .foregroundStyle(secondaryColor)
                .padding(.leading, Spacing.xs)
            
            Text("初回登録時と同じ Apple ID・同じメール設定でログインしてください。別のメールに見える場合は、設定のアカウント切り替えか、登録時に使ったメールアドレスをお試しください。")
                .font(.scaledBodySmall())
                .foregroundStyle(secondaryColor)
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
    
    private func faqSection(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.scaledLabelMedium())
                .foregroundStyle(secondaryColor)
                .padding(.leading, Spacing.xs)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(item.0)
                            .font(.scaledBodyLarge().weight(.semibold))
                            .foregroundStyle(primaryColor)
                        Text(item.1)
                            .font(.scaledBodySmall())
                            .foregroundStyle(secondaryColor)
                    }
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if index < items.count - 1 {
                        Divider().padding(.leading, Spacing.lg)
                    }
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
    
    private var troubleshootSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("トラブルシュート")
                .font(.scaledLabelMedium())
                .foregroundStyle(secondaryColor)
                .padding(.leading, Spacing.xs)
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label {
                    Text("通信エラー: Wi‑Fi / モバイルデータを確認し、アプリを再起動してください。")
                        .font(.scaledBodySmall())
                        .foregroundStyle(secondaryColor)
                } icon: {
                    Image(systemName: "wifi.exclamationmark")
                }
                
                Label {
                    Text("AI が応答しない: 10秒以内に応答がない場合は再送信してください。")
                        .font(.scaledBodySmall())
                        .foregroundStyle(secondaryColor)
                } icon: {
                    Image(systemName: "clock.badge.exclamationmark")
                }
            }
            .padding(Spacing.lg)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("お問い合わせ")
                .font(.scaledLabelMedium())
                .foregroundStyle(secondaryColor)
            
            Link(destination: URL(string: "mailto:support@plotty.app")!) {
                HStack {
                    Text("support@plotty.app")
                        .font(.scaledBodyMedium())
                    Spacer()
                    Image(systemName: "envelope")
                }
                .foregroundStyle(primaryColor)
                .padding(Spacing.lg)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
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
        HelpView()
            .ambientBackground()
    }
}
