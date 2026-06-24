import Foundation

// MARK: - Edge DTO ↔ iOS Item

enum PlotEntityMapper {
    private static let defaultScheduleSwatch: AccentSwatch = .sky
    private static let defaultMemoAccent: AccentSwatch = .graphite
    private static let defaultEventDuration: TimeInterval = 3600

    // MARK: DTO → Item

    static func calendarEvent(from dto: PlotEntityListItemDTO) -> CalendarEvent? {
        guard dto.type == .schedule else { return nil }
        let start = dto.startAt ?? Date()
        let end = dto.endAt ?? start.addingTimeInterval(defaultEventDuration)
        return CalendarEvent(
            id: dto.id,
            title: dto.title,
            startTime: start,
            endTime: end,
            swatch: defaultScheduleSwatch,
            location: dto.location ?? "",
            notes: dto.notes ?? "",
            isAllDay: dto.isAllDay ?? false
        )
    }

    static func calendarEvent(from dto: PlotCreatedEntityDTO) -> CalendarEvent? {
        guard dto.type == .schedule else { return nil }
        let start = dto.startAt ?? Date()
        let end = dto.endAt ?? start.addingTimeInterval(defaultEventDuration)
        return CalendarEvent(
            id: dto.id,
            title: dto.title,
            startTime: start,
            endTime: end,
            swatch: defaultScheduleSwatch,
            location: dto.location ?? "",
            notes: dto.notes ?? "",
            isAllDay: dto.isAllDay ?? false
        )
    }

    static func todoItem(from dto: PlotEntityListItemDTO) -> TodoItem? {
        guard dto.type == .task else { return nil }
        return TodoItem(
            id: dto.id,
            title: dto.title,
            isCompleted: dto.isCompleted ?? false,
            dueDate: dto.dueDate,
            priority: TodoItem.Priority(apiPriority: dto.priority ?? 2),
            createdAt: dto.createdAt ?? dto.updatedAt ?? Date()
        )
    }

    static func todoItem(from dto: PlotCreatedEntityDTO) -> TodoItem? {
        guard dto.type == .task else { return nil }
        return TodoItem(
            id: dto.id,
            title: dto.title,
            isCompleted: dto.isCompleted ?? false,
            dueDate: dto.dueDate,
            priority: TodoItem.Priority(apiPriority: dto.priority ?? 2),
            createdAt: Date()
        )
    }

    static func memoItem(from dto: PlotEntityListItemDTO) -> MemoItem? {
        guard dto.type == .memo else { return nil }
        return MemoItem(
            id: dto.id,
            title: dto.title,
            content: dto.content ?? "",
            updatedAt: dto.updatedAt ?? Date(),
            isPinned: dto.isPinned ?? false,
            accent: defaultMemoAccent
        )
    }

    static func memoItem(from dto: PlotCreatedEntityDTO) -> MemoItem? {
        guard dto.type == .memo else { return nil }
        return MemoItem(
            id: dto.id,
            title: dto.title,
            content: dto.content ?? "",
            updatedAt: Date(),
            isPinned: dto.isPinned ?? false,
            accent: defaultMemoAccent
        )
    }

    static func listItem(from dto: PlotEntityListItemDTO) -> PlotMappedEntity? {
        switch dto.type {
        case .schedule:
            guard let event = calendarEvent(from: dto) else { return nil }
            return .schedule(event)
        case .task:
            guard let todo = todoItem(from: dto) else { return nil }
            return .task(todo)
        case .memo:
            guard let memo = memoItem(from: dto) else { return nil }
            return .memo(memo)
        }
    }

    // MARK: Item → PATCH body

    static func patchRequest(for event: CalendarEvent) -> PlotPatchEntityRequestDTO {
        PlotPatchEntityRequestDTO(
            title: event.title,
            startAt: event.startTime,
            endAt: event.endTime,
            isAllDay: event.isAllDay,
            location: event.location,
            notes: event.notes
        )
    }

    static func patchRequest(for todo: TodoItem) -> PlotPatchEntityRequestDTO {
        PlotPatchEntityRequestDTO(
            title: todo.title,
            dueDate: todo.dueDate,
            isCompleted: todo.isCompleted,
            priority: todo.priority.apiPriority
        )
    }

    static func patchRequest(for memo: MemoItem) -> PlotPatchEntityRequestDTO {
        PlotPatchEntityRequestDTO(
            title: memo.title,
            content: memo.content,
            isPinned: memo.isPinned
        )
    }

    // MARK: PATCH レスポンスをローカル Item にマージ（Edge が狭い subset のみ返す場合も既存値を保持）

    static func merge(_ event: CalendarEvent, with dto: PlotEntityListItemDTO, swatch: AccentSwatch) -> CalendarEvent {
        var merged = event
        merged.title = dto.title
        if let startAt = dto.startAt { merged.startTime = startAt }
        if let endAt = dto.endAt { merged.endTime = endAt }
        if let isAllDay = dto.isAllDay { merged.isAllDay = isAllDay }
        if let location = dto.location { merged.location = location }
        if let notes = dto.notes { merged.notes = notes }
        merged.swatch = swatch
        return merged
    }

    static func merge(_ todo: TodoItem, with dto: PlotEntityListItemDTO) -> TodoItem {
        var merged = todo
        merged.title = dto.title
        if let dueDate = dto.dueDate { merged.dueDate = dueDate }
        if let isCompleted = dto.isCompleted { merged.isCompleted = isCompleted }
        if let priority = dto.priority { merged.priority = TodoItem.Priority(apiPriority: priority) }
        return merged
    }

    static func merge(_ memo: MemoItem, with dto: PlotEntityListItemDTO, accent: AccentSwatch) -> MemoItem {
        var merged = memo
        merged.title = dto.title
        if let content = dto.content { merged.content = content }
        if let isPinned = dto.isPinned { merged.isPinned = isPinned }
        if let updatedAt = dto.updatedAt { merged.updatedAt = updatedAt }
        merged.accent = accent
        return merged
    }
}

enum PlotMappedEntity: Sendable {
    case schedule(CalendarEvent)
    case task(TodoItem)
    case memo(MemoItem)
}

// MARK: - task priority（API 1–3 ↔ iOS 0–2）

extension TodoItem.Priority {
    init(apiPriority: Int) {
        switch apiPriority {
        case 1:
            self = .low
        case 3:
            self = .high
        default:
            self = .medium
        }
    }

    var apiPriority: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        }
    }
}
