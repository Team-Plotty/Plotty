import Foundation

// MARK: - 本実装時削除（モック AI 応答・API 接続前のローカル登録）
enum ChatMockResponder {
    static let responseTimeout: Duration = .seconds(10)
    
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
        dataStore: PlotDataStore,
        language: AppLanguage
    ) -> ChatMessage {
        let title = String(body.prefix(20))
        let summary = register(body: body, title: title, category: category, dataStore: dataStore, language: language)
        let aiText = confirmationText(for: category, language: language)
        
        return ChatMessage(
            role: .ai,
            text: aiText,
            chips: [],
            timestamp: Date(),
            registrationSummary: summary
        )
    }
    
    static func reclassify(
        summary: ChatRegistrationSummary,
        to newCategory: PlotChatCategory,
        dataStore: PlotDataStore,
        language: AppLanguage
    ) -> ChatRegistrationSummary {
        if let entityID = summary.linkedEntityID {
            removeEntity(id: entityID, category: summary.category, dataStore: dataStore)
        }
        return register(
            body: summary.sourceBody,
            title: summary.title,
            category: newCategory,
            dataStore: dataStore,
            language: language
        )
    }
    
    private static func register(
        body: String,
        title: String,
        category: PlotChatCategory,
        dataStore: PlotDataStore,
        language: AppLanguage
    ) -> ChatRegistrationSummary {
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
            return ChatRegistrationSummary(
                category: .schedule,
                title: title,
                detail: PlotDateFormatter.dateTime(start, language: language),
                linkedEntityID: event.id,
                sourceBody: body
            )
            
        case .task:
            let todo = TodoItem(title: title, isCompleted: false, dueDate: Date(), priority: .medium)
            dataStore.addTodo(todo)
            let detail = language == .japanese ? "優先度: 中" : "Priority: Medium"
            return ChatRegistrationSummary(
                category: .task,
                title: title,
                detail: detail,
                linkedEntityID: todo.id,
                sourceBody: body
            )
            
        case .memo:
            let memo = MemoItem(title: title, content: body, updatedAt: Date(), isPinned: false, accent: .graphite)
            dataStore.addMemo(memo)
            let detail = language == .japanese ? "メモに保存" : "Saved to memo"
            return ChatRegistrationSummary(
                category: .memo,
                title: title,
                detail: detail,
                linkedEntityID: memo.id,
                sourceBody: body
            )
        }
    }
    
    private static func removeEntity(id: UUID, category: PlotChatCategory, dataStore: PlotDataStore) {
        switch category {
        case .schedule: dataStore.deleteEvent(id: id)
        case .task: dataStore.deleteTodo(id: id)
        case .memo: dataStore.deleteMemo(id: id)
        }
    }
    
    private static func confirmationText(for category: PlotChatCategory, language: AppLanguage) -> String {
        switch (category, language) {
        case (.schedule, .japanese): return "カレンダーに登録したよ！"
        case (.schedule, .english): return "Added to calendar!"
        case (.task, .japanese): return "ToDoに追加したよ！"
        case (.task, .english): return "Added to ToDo!"
        case (.memo, .japanese): return "メモに残しておいたよ！"
        case (.memo, .english): return "Saved to memo!"
        }
    }
}
