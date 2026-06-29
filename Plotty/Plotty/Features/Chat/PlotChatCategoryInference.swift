import Foundation

// MARK: - ローカルカテゴリ推論（API 呼び出しなし・E3）
enum PlotChatCategoryInference {
    struct Result: Equatable {
        let category: PlotChatCategory
        /// アクセシビリティ用の短い説明
        let hint: String
    }

    /// 入力文から登録先カテゴリを推論する。確信が低い場合は `nil`。
    static func suggest(for text: String, language: AppLanguage) -> Result? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 2 else { return nil }

        let scores = scoreCategories(in: normalized, language: language)
        guard let top = scores.max(by: { $0.value < $1.value }),
              top.value >= minimumScore,
              scores.filter({ $0.value == top.value }).count == 1
        else { return nil }

        let secondBest = scores
            .filter { $0.key != top.key }
            .map(\.value)
            .max() ?? 0
        guard top.value - secondBest >= scoreMargin else { return nil }

        return Result(category: top.key, hint: hint(for: top.key, language: language))
    }

    // MARK: - Private

    private static let minimumScore = 2
    private static let scoreMargin = 1

    private static func scoreCategories(
        in text: String,
        language: AppLanguage
    ) -> [PlotChatCategory: Int] {
        var scores: [PlotChatCategory: Int] = [.schedule: 0, .task: 0, .memo: 0]
        let lower = text.lowercased()

        if containsDateTimeSignal(lower) {
            scores[.schedule, default: 0] += 3
        }

        for keyword in scheduleKeywords(language: language) where lower.contains(keyword) {
            scores[.schedule, default: 0] += 2
        }

        for keyword in taskKeywords(language: language) where lower.contains(keyword) {
            scores[.task, default: 0] += 2
        }

        for keyword in memoKeywords(language: language) where lower.contains(keyword) {
            scores[.memo, default: 0] += 2
        }

        if looksLikeActionPhrase(lower, language: language) {
            scores[.task, default: 0] += 1
        }

        if looksLikeReminderPhrase(lower, language: language) {
            scores[.memo, default: 0] += 1
        }

        return scores
    }

    private static func containsDateTimeSignal(_ text: String) -> Bool {
        let patterns = [
            #"\d{1,2}[:：時]"#,
            #"(午前|午後|am|pm)"#,
            #"(今日|明日|明後日|来週|再来週|今週|来月|今月)"#,
            #"(月曜|火曜|水曜|木曜|金曜|土曜|日曜)"#,
            #"(monday|tuesday|wednesday|thursday|friday|saturday|sunday)"#,
            #"\d{1,2}/\d{1,2}"#,
        ]
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }

    private static func scheduleKeywords(language: AppLanguage) -> [String] {
        switch language {
        case .japanese:
            return [
                "会議", "予定", "ミーティング", "打ち合わせ", "面談", "ランチ", "ディナー",
                "予約", "集合", "アポ", "カレンダー", "訪問", "出張", "飛行機", "電車",
            ]
        case .english:
            return [
                "meeting", "appointment", "schedule", "calendar", "lunch", "dinner",
                "call at", "interview", "reservation",
            ]
        }
    }

    private static func taskKeywords(language: AppLanguage) -> [String] {
        switch language {
        case .japanese:
            return [
                "やる", "する", "提出", "完了", "タスク", "todo", "締切", "期限", "までに",
                "購入", "買う", "送る", "連絡", "確認", "返信", "支払", "洗濯", "掃除",
                "忘れず", "やらなきゃ", "しなきゃ",
            ]
        case .english:
            return [
                "todo", "task", "submit", "finish", "complete", "deadline", "due",
                "buy", "send", "reply", "call back", "pay", "clean",
            ]
        }
    }

    private static func memoKeywords(language: AppLanguage) -> [String] {
        switch language {
        case .japanese:
            return [
                "メモ", "覚えて", "記録", "アイデア", "忘れないで", "書いて", "覚書",
                "参考", "リスト", "メモして", "控えて", "残して",
            ]
        case .english:
            return [
                "memo", "note", "remember", "idea", "jot down", "save this", "reference",
                "wishlist", "keep in mind",
            ]
        }
    }

    private static func looksLikeActionPhrase(_ text: String, language: AppLanguage) -> Bool {
        switch language {
        case .japanese:
            return text.hasSuffix("する")
                || text.hasSuffix("したい")
                || text.contains("しておく")
                || text.contains("しとく")
        case .english:
            return text.hasPrefix("need to ")
                || text.hasPrefix("have to ")
                || text.hasSuffix(" to do")
        }
    }

    private static func looksLikeReminderPhrase(_ text: String, language: AppLanguage) -> Bool {
        switch language {
        case .japanese:
            return text.contains("について")
                || text.contains("という")
                || text.contains("らしい")
        case .english:
            return text.contains("about ")
                || text.contains("that ")
        }
    }

    private static func hint(for category: PlotChatCategory, language: AppLanguage) -> String {
        switch (category, language) {
        case (.schedule, .japanese): return "カレンダーに登録しそう"
        case (.task, .japanese): return "ToDo に登録しそう"
        case (.memo, .japanese): return "メモに保存しそう"
        case (.schedule, .english): return "Looks like a calendar event"
        case (.task, .english): return "Looks like a to-do"
        case (.memo, .english): return "Looks like a memo"
        }
    }
}
