import Foundation

// MARK: - モック AI 応答（API 接続前のローカル登録）
enum ChatMockResponder {
    static func inferCategory(from text: String) -> PlotChatCategory {
        if text.contains("予定") || text.contains("会議") || text.contains("時") {
            return .schedule
        }
        if text.contains("メモ") || text.contains("覚え") {
            return .memo
        }
        return .task
    }
    
    static func respond(
        body: String,
        category: PlotChatCategory,
        dataStore: PlotDataStore
    ) -> ChatMessage {
        let title = String(body.prefix(20))
        let summary: ChatRegistrationSummary
        let aiText: String
        
        switch category {
        case .schedule:
            let start = Date().addingTimeInterval(3600)
            let end = start.addingTimeInterval(3600)
            let event = CalendarEvent(
                title: title,
                startTime: start,
                endTime: end,
                swatch: .sky,
                location: "",
                notes: body,
                isAllDay: false
            )
            dataStore.addEvent(event)
            summary = ChatRegistrationSummary(
                category: .schedule,
                title: title,
                detail: start.formatted(date: .abbreviated, time: .shortened)
            )
            aiText = "予定として登録したよ！"
            
        case .task:
            let todo = TodoItem(title: title, isCompleted: false, dueDate: Date(), priority: .medium)
            dataStore.addTodo(todo)
            summary = ChatRegistrationSummary(category: .task, title: title, detail: "優先度: 中")
            aiText = "タスクに追加したよ！"
            
        case .memo:
            let memo = MemoItem(title: title, content: body, updatedAt: Date(), isPinned: false, accent: .graphite)
            dataStore.addMemo(memo)
            summary = ChatRegistrationSummary(category: .memo, title: title, detail: "メモに保存")
            aiText = "メモに残しておいたよ！"
        }
        
        return ChatMessage(
            role: .ai,
            text: aiText,
            chips: [],
            timestamp: Date(),
            registrationSummary: summary
        )
    }
}
