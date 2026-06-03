import SwiftUI

// MARK: - ヘルプ画面
struct HelpView: View {
    @Environment(\.plotColorScheme) private var plotColorScheme
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
        SettingsGlassSection(title: "Apple の非公開メール（Hide My Email）") {
            Text("初回登録時と同じ Apple ID・同じメール設定でログインしてください。別のメールに見える場合は、設定のアカウント切り替えか、登録時に使ったメールアドレスをお試しください。")
                .font(.scaledBodySmall())
                .foregroundStyle(secondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
        }
    }
    
    private func faqSection(title: String, items: [(String, String)]) -> some View {
        SettingsGlassSection(title: title) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.0)
                        .font(.scaledBodyLarge().weight(.semibold))
                        .foregroundStyle(primaryColor)
                    Text(item.1)
                        .font(.scaledBodySmall())
                        .foregroundStyle(secondaryColor)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if index < items.count - 1 {
                    SettingsInsetDivider()
                }
            }
        }
    }
    
    private var troubleshootSection: some View {
        SettingsGlassSection(title: "トラブルシュート") {
            troubleshootRow(
                icon: "wifi.exclamationmark",
                text: "通信エラー: Wi‑Fi / モバイルデータを確認し、アプリを再起動してください。"
            )
            SettingsInsetDivider()
            troubleshootRow(
                icon: "clock.badge.exclamationmark",
                text: "AI が応答しない: 10秒以内に応答がない場合は再送信してください。"
            )
        }
    }
    
    private func troubleshootRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(secondaryColor)
                .frame(width: 28, alignment: .center)
            
            Text(text)
                .font(.scaledBodySmall())
                .foregroundStyle(secondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
    
    private var contactSection: some View {
        SettingsGlassSection(title: "お問い合わせ") {
            Link(destination: URL(string: "mailto:support@plotty.app")!) {
                HStack(spacing: Spacing.sm) {
                    Text("support@plotty.app")
                        .font(.scaledBodyMedium())
                        .foregroundStyle(primaryColor)
                    Spacer(minLength: 0)
                    Image(systemName: "envelope")
                        .font(.system(size: 18))
                        .foregroundStyle(secondaryColor)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .contentShape(Rectangle())
            }
        }
    }
    
    private var primaryColor: Color {
        PlotColors.textPrimary(plotColorScheme)
    }
    
    private var secondaryColor: Color {
        PlotColors.textSecondary(plotColorScheme)
    }
}

#Preview {
    NavigationStack {
        HelpView()
            .ambientBackground()
    }
    .environment(\.plotColorScheme, .dark)
}
