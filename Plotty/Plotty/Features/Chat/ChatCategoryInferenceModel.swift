import SwiftUI

// MARK: - 入力中カテゴリ推論（500ms デバウンス・API なし）
@Observable
@MainActor
final class ChatCategoryInferenceModel {
    private(set) var suggestion: PlotChatCategoryInference.Result?
    private var debounceTask: Task<Void, Never>?

    /// 入力文の変化に応じて推論を更新する。
    func updateDraft(
        _ text: String,
        language: AppLanguage,
        isEnabled: Bool
    ) {
        debounceTask?.cancel()

        guard isEnabled else {
            suggestion = nil
            return
        }

        let draft = text
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            suggestion = PlotChatCategoryInference.suggest(for: draft, language: language)
        }
    }

    func reset() {
        debounceTask?.cancel()
        suggestion = nil
    }
}
