import SwiftUI

// MARK: - メモ詳細シート（カード上で省略された本文も全文表示する）
struct MemoDetailSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appSettings) private var appSettings

    let memo: MemoItem
    let onClose: () -> Void
    let onEdit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(memo.accent.color)
                                .frame(width: 4, height: 20)

                            Text(memo.title)
                                .font(.scaledTitleSmall())
                                .foregroundStyle(textColor)
                                .textSelection(.enabled)

                            if memo.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(memo.accent.color)
                                    .accessibilityLabel("ピン留め済み")
                            }
                        }

                        Text("更新 \(PlotDateFormatter.dateTime(memo.updatedAt, language: appSettings.language))")
                            .font(.scaledCaption())
                            .foregroundStyle(tertiaryTextColor)

                        if memo.content.isEmpty {
                            Text("本文はありません")
                                .font(.scaledBodyMedium())
                                .foregroundStyle(tertiaryTextColor)
                        } else {
                            Text(memo.content)
                                .font(.scaledBodyMedium())
                                .foregroundStyle(secondaryTextColor)
                                .bodyLineSpacing()
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("編集", action: onEdit)
                    .filledButtonStyle()
            }
            .padding(Spacing.lg)
            .navigationTitle("メモの詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onClose)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary
    }
}
