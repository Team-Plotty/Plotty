import SwiftUI

// MARK: - チャットメッセージのデータモデル
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let text: String
    let chips: [String]
    let timestamp: Date
}

/// チャット画面で「日付ごと」に並べるための内部モデル（1日分のメッセージの束）
private struct ChatDaySection: Identifiable {
    let id: String
    let day: Date
    let messages: [ChatMessage]
}

// MARK: - チャットタブの画面
struct ChatTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// 親のタブ選択（チャット以外に切り替えたらキーボードを閉じる）
    var selectedTab: TabItem
    
    //---API やローカル DB に差し替える---//
    @State private var messages: [ChatMessage] = ChatMessage.sampleData
    @State private var draftMessage = ""
    @FocusState private var isComposerFocused: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(daySections) { section in
                    dayHeader(section.day)
                    
                    ForEach(section.messages) { message in
                        ChatBubble(
                            role: message.role,
                            text: message.text,
                            chips: message.chips
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                isComposerFocused = false
            }
        )
        .onChange(of: selectedTab) { _, newTab in
            if newTab != .chat {
                isComposerFocused = false
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatComposerBarInline(text: $draftMessage, isFocused: $isComposerFocused, onSend: commitDraft)
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.sm)
        }
    }
    
    private var daySections: [ChatDaySection] {
        let cal = Calendar.current
        let sorted = messages.sorted { $0.timestamp < $1.timestamp }
        let grouped = Dictionary(grouping: sorted) { cal.startOfDay(for: $0.timestamp) }
        return grouped.keys.sorted().map { day in
            ChatDaySection(
                id: "\(day.timeIntervalSince1970)",
                day: day,
                messages: grouped[day] ?? []
            )
        }
    }
    
    private func dayHeader(_ day: Date) -> some View {
        Text(day.formatted(date: .long, time: .omitted))
            .font(.scaledCaption())
            .foregroundStyle(colorScheme == .dark ? Color.darkTextTertiary : Color.lightTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
    }
    
    private func commitDraft() {
        let body = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let newMessage = ChatMessage(role: .user, text: body, chips: [], timestamp: Date())
        messages.append(newMessage)
        draftMessage = ""
    }
}

// MARK: - プレビュー用のダミーメッセージ
extension ChatMessage {
    static var sampleData: [ChatMessage] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return [
            ChatMessage(
                role: .ai,
                text: "昨日のタスクは完了していますか？",
                chips: [],
                timestamp: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: yesterday)!
            ),
            ChatMessage(
                role: .user,
                text: "まだ一部残ってる",
                chips: [],
                timestamp: Calendar.current.date(bySettingHour: 21, minute: 5, second: 0, of: yesterday)!
            ),
            ChatMessage(
                role: .ai,
                text: "こんにちは。予定の確認やメモの整理など、手伝いできることがあれば声をかけてください。",
                chips: ["今日の重点", "カレンダー連携"],
                timestamp: Date().addingTimeInterval(-300)
            ),
            ChatMessage(
                role: .user,
                text: "明日の午後に空きはある？",
                chips: [],
                timestamp: Date().addingTimeInterval(-240)
            ),
            ChatMessage(
                role: .ai,
                text: "明日は 14:00〜 にブロックが空いています。必要ならそこに仮押さえできます。",
                chips: ["14:00 — 空き"],
                timestamp: Date().addingTimeInterval(-180)
            ),
        ]
    }
}

// MARK: - チャット下部の入力欄（iOS 26 Liquid Glass）
private struct ChatComposerBarInline: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var onSend: () -> Void
    
    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canSend: Bool {
        !trimmed.isEmpty
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.darkTextPrimary : Color.lightTextPrimary
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(secondaryColor)
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)
            .accessibilityLabel("追加")
            
            TextField("", text: $text, prompt: Text("メッセージ").foregroundStyle(secondaryColor), axis: .vertical)
                .font(.scaledBodyMedium())
                .foregroundStyle(primaryColor)
                .multilineTextAlignment(.leading)
                .lineLimit(1...8)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.send)
                .frame(minHeight: 24, alignment: .center)
                .onSubmit {
                    if canSend { send() }
                }
            
            Button {
                send()
            } label: {
                ZStack {
                    Circle()
                        .fill(canSend ? primaryColor : secondaryColor.opacity(0.3))
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSend
                            ? (colorScheme == .dark ? Color.darkBase : Color.lightBase)
                            : secondaryColor.opacity(0.6))
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("送信")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
    
    private func send() {
        guard canSend else { return }
        onSend()
        isFocused = false
    }
}

#Preview {
    ChatTabView(selectedTab: .chat)
        .ambientBackground()
        .preferredColorScheme(.dark)
}
