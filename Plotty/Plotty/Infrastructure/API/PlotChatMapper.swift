import Foundation

// MARK: - Edge チャット DTO ↔ ChatMessage

enum PlotChatMapper {
    static func assistantMessage(
        from response: PlotPostChatMessagesResponseDTO,
        sourceBody: String,
        language: AppLanguage
    ) -> ChatMessage {
        let summary = registrationSummary(
            from: response.createdEntities.first,
            sourceBody: sourceBody,
            language: language
        )
        return ChatMessage(
            id: response.messageId,
            role: .ai,
            text: response.confirmationText,
            chips: [],
            timestamp: Date(),
            registrationSummary: summary
        )
    }

    static func assistantMessage(
        from response: PlotPostReclassifyResponseDTO,
        sourceBody: String,
        language: AppLanguage
    ) -> ChatMessage {
        let summary = registrationSummary(
            from: response.migratedEntity,
            sourceBody: sourceBody,
            language: language
        )
        return ChatMessage(
            role: .ai,
            text: response.confirmationText,
            chips: [],
            timestamp: Date(),
            registrationSummary: summary
        )
    }

    static func registrationSummary(
        from entity: PlotCreatedEntityDTO?,
        sourceBody: String,
        language: AppLanguage
    ) -> ChatRegistrationSummary? {
        guard let entity else { return nil }
        return registrationSummary(
            category: entity.type.chatCategory,
            entityID: entity.id,
            title: entity.title,
            detail: detail(for: entity, language: language),
            sourceBody: sourceBody
        )
    }

    static func registrationSummary(
        from entity: PlotEntityListItemDTO,
        sourceBody: String,
        language: AppLanguage
    ) -> ChatRegistrationSummary {
        registrationSummary(
            category: entity.type.chatCategory,
            entityID: entity.id,
            title: entity.title,
            detail: detail(for: entity, language: language),
            sourceBody: sourceBody
        )
    }

    /// `created_entities[]` を各 Item 一覧へ反映（C5）
    static func applyCreatedEntities(_ entities: [PlotCreatedEntityDTO], to store: PlotDataStore) {
        for dto in entities {
            switch dto.type {
            case .schedule:
                guard let event = PlotEntityMapper.calendarEvent(from: dto) else { continue }
                guard !store.events.contains(where: { $0.id == event.id }) else { continue }
                store.events.append(event)
            case .task:
                guard let todo = PlotEntityMapper.todoItem(from: dto) else { continue }
                guard !store.todos.contains(where: { $0.id == todo.id }) else { continue }
                store.todos.insert(todo, at: 0)
            case .memo:
                guard let memo = PlotEntityMapper.memoItem(from: dto) else { continue }
                guard !store.memos.contains(where: { $0.id == memo.id }) else { continue }
                store.memos.insert(memo, at: 0)
            }
        }
    }

    /// 再分類: 元実体を Store から除去し、移行先を追加（C6）
    static func applyReclassification(
        sourceType: PlotEntityType,
        sourceID: UUID,
        migratedEntity: PlotEntityListItemDTO,
        to store: PlotDataStore
    ) {
        switch sourceType {
        case .schedule:
            store.events.removeAll { $0.id == sourceID }
        case .task:
            store.todos.removeAll { $0.id == sourceID }
        case .memo:
            store.memos.removeAll { $0.id == sourceID }
        }

        switch migratedEntity.type {
        case .schedule:
            if let event = PlotEntityMapper.calendarEvent(from: migratedEntity) {
                store.events.append(event)
            }
        case .task:
            if let todo = PlotEntityMapper.todoItem(from: migratedEntity) {
                store.todos.insert(todo, at: 0)
            }
        case .memo:
            if let memo = PlotEntityMapper.memoItem(from: migratedEntity) {
                store.memos.insert(memo, at: 0)
            }
        }
    }

    private static func registrationSummary(
        category: PlotChatCategory,
        entityID: UUID,
        title: String,
        detail: String,
        sourceBody: String
    ) -> ChatRegistrationSummary {
        ChatRegistrationSummary(
            category: category,
            title: title,
            detail: detail,
            linkedEntityID: entityID,
            sourceBody: sourceBody
        )
    }

    private static func detail(for entity: PlotCreatedEntityDTO, language: AppLanguage) -> String {
        switch entity.type {
        case .schedule:
            let start = entity.startAt ?? Date()
            return PlotDateFormatter.dateTime(start, language: language)
        case .task:
            if let dueDate = entity.dueDate {
                return PlotDateFormatter.dateTime(dueDate, language: language)
            }
            return language == .japanese ? "ToDo に登録" : "Added to ToDo"
        case .memo:
            return language == .japanese ? "メモに保存" : "Saved to memo"
        }
    }

    private static func detail(for entity: PlotEntityListItemDTO, language: AppLanguage) -> String {
        switch entity.type {
        case .schedule:
            let start = entity.startAt ?? Date()
            return PlotDateFormatter.dateTime(start, language: language)
        case .task:
            if let dueDate = entity.dueDate {
                return PlotDateFormatter.dateTime(dueDate, language: language)
            }
            return language == .japanese ? "ToDo に登録" : "Added to ToDo"
        case .memo:
            return language == .japanese ? "メモに保存" : "Saved to memo"
        }
    }
}
