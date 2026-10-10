import SwiftUI

// MARK: - 1 文字ずつ表示するテキスト（AI 応答の到着演出）
/// 未表示の文字も透明で描画しておき、最初から全文ぶんの行数を確保する。
/// 表示済みの文字数だけでレイアウトすると、折り返しのたびに下のカードや行がガタつくため。
struct ChatTypewriterText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let text: String
    let animates: Bool
    var onFinished: () -> Void = {}

    @State private var revealedCount: Int

    /// 1 文字あたりの表示間隔。長文でも待たせすぎないよう、全体は `maxDuration` に収める
    private static let characterInterval: Double = 0.035
    private static let maxDuration: Double = 1.6

    init(text: String, animates: Bool, onFinished: @escaping () -> Void = {}) {
        self.text = text
        self.animates = animates
        self.onFinished = onFinished
        _revealedCount = State(initialValue: animates ? 0 : .max)
    }

    var body: some View {
        Text(displayedText)
            .accessibilityLabel(text)
            .task(id: text) {
                await reveal()
            }
    }

    private var displayedText: AttributedString {
        let characters = Array(text)
        let splitIndex = min(revealedCount, characters.count)
        var visible = AttributedString(String(characters[..<splitIndex]))
        var hidden = AttributedString(String(characters[splitIndex...]))
        hidden.foregroundColor = .clear
        visible.append(hidden)
        return visible
    }

    private func reveal() async {
        guard animates else { return }
        let total = text.count
        guard total > 0, !reduceMotion else {
            revealedCount = .max
            onFinished()
            return
        }

        let interval = min(Self.characterInterval, Self.maxDuration / Double(total))
        for count in 1 ... total {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }
            revealedCount = count
        }
        onFinished()
    }
}
