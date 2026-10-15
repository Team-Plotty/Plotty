import Foundation

// MARK: - Edge チャット DTO ↔ ChatMessage

enum PlotChatMapper {
    static func assistantMessage(
        from response: PlotPostChatMessagesResponseDTO,
        language: AppLanguage
    ) -> ChatMessage {
        ChatMessage(
            id: response.assistantMessageId,
            role: .ai,
            text: response.confirmationText,
            chips: [],
            timestamp: Date(),
            registrationSummary: registrationSummary(from: response.createdEntities.first, language: language)
        )
    }

    static func chatMessages(
        from items: [PlotChatHistoryMessageDTO],
        language: AppLanguage
    ) -> [ChatMessage] {
        items.map { item in
            switch item.role {
            case .user:
                return ChatMessage(
                    id: item.id,
                    role: .user,
                    text: item.text,
                    chips: [],
                    timestamp: item.createdAt
                )
            case .assistant:
                return ChatMessage(
                    id: item.id,
                    role: .ai,
                    text: item.text,
                    chips: [],
                    timestamp: item.createdAt,
                    registrationSummary: registrationSummary(from: item.createdEntities?.first, language: language)
                )
            }
        }
    }

    static func registrationSummary(
        from entity: PlotCreatedEntityDTO?,
        language: AppLanguage
    ) -> ChatRegistrationSummary? {
        guard let entity else { return nil }
        return ChatRegistrationSummary(
            category: entity.type.chatCategory,
            title: entity.title,
            detail: detail(for: entity, language: language),
            linkedEntityID: entity.id
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

    /// 登録カードの補足。予定は「いつからいつまで」、タスクは「いつまでに」が一目で分かるようにする
    private static func detail(for entity: PlotCreatedEntityDTO, language: AppLanguage) -> String {
        switch entity.type {
        case .schedule:
            return PlotDateFormatter.eventPeriod(
                start: entity.startAt ?? Date(),
                end: entity.endAt,
                isAllDay: entity.isAllDay ?? false,
                language: language
            )
        case .task:
            if let dueDate = entity.dueDate {
                let deadline = PlotDateFormatter.deadline(dueDate, hasTime: entity.dueHasTime ?? false, language: language)
                return language == .japanese ? "期限 \(deadline)" : "Due \(deadline)"
            }
            return language == .japanese ? "タスクに登録" : "Added to tasks"
        case .memo:
            return language == .japanese ? "メモに保存" : "Saved to memo"
        }
    }
}
