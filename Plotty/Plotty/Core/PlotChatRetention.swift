import Foundation

// MARK: - チャットメッセージ保持期間（docs/02, 09 と一致）
enum PlotChatRetention {
  /// `messages` の保持期間（720 時間 = 30 日）
  static let messageLifetime: TimeInterval = 720 * 3600

  static func canReclassify(messageCreatedAt: Date, relativeTo now: Date = Date()) -> Bool {
    now.timeIntervalSince(messageCreatedAt) < messageLifetime
  }

  static func reclassifyDisabledMessage(language: AppLanguage) -> String {
    switch language {
    case .japanese:
      return "元メッセージから30日経過したため、カテゴリを変更できません。"
    case .english:
      return "Category changes aren't available 30 days after the original message."
    }
  }
}

enum PlotChatReclassifyPolicy {
  static func isAllowed(for message: ChatMessage) -> Bool {
    guard message.registrationSummary != nil else { return false }
    let anchor = message.registrationSummary?.sourceMessageCreatedAt ?? message.timestamp
    return PlotChatRetention.canReclassify(messageCreatedAt: anchor)
  }
}
