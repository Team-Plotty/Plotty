import SwiftUI

// MARK: - 今日の進捗（リスト内カード用）
struct TodoProgressBlock: View {
    let completedCount: Int
    let totalCount: Int
    
    private var progressFraction: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(totalCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                Text("今日の進捗")
                    .font(.scaledLabelMedium())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(completedCount) / \(totalCount)")
                    .font(.scaledBodyMedium().monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .accessibilityLabel("\(completedCount)件完了、全\(totalCount)件")
            }
            
            ProgressView(value: Double(completedCount), total: Double(max(totalCount, 1)))
                .progressViewStyle(.linear)
                .tint(Color.accentColor)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("進捗")
                .accessibilityValue("\(Int(progressFraction * 100))パーセント")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .plotListCardGlass()
    }
}

// MARK: - 今日の進捗（ヘッダー統合用・コンパクト）
struct TodoHeaderProgress: View {
    let completedCount: Int
    let totalCount: Int
    
    private var progressFraction: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(totalCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .center, spacing: Spacing.xs) {
                Text("今日の進捗")
                    .font(.scaledCaption())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(completedCount) / \(totalCount)")
                    .font(.scaledCaption().monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .accessibilityLabel("\(completedCount)件完了、全\(totalCount)件")
            }
            
            ProgressView(value: Double(completedCount), total: Double(max(totalCount, 1)))
                .progressViewStyle(.linear)
                .tint(Color.accentColor)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("進捗")
                .accessibilityValue("\(Int(progressFraction * 100))パーセント")
        }
    }
}
