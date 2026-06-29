import Foundation

// MARK: - 共通

enum PlotEntityType: String, Codable, Sendable, CaseIterable {
    case schedule
    case task
    case memo
}

extension PlotEntityType {
    var chatCategory: PlotChatCategory {
        switch self {
        case .schedule: return .schedule
        case .task: return .task
        case .memo: return .memo
        }
    }

    /// PATCH `/api/v1/schedules|tasks|memos/{id}`
    var patchCollectionSegment: String {
        switch self {
        case .schedule: return "schedules"
        case .task: return "tasks"
        case .memo: return "memos"
        }
    }

    func patchPath(id: UUID) -> String {
        "api/v1/\(patchCollectionSegment)/\(id.uuidString.lowercased())"
    }

    func deletePath(id: UUID) -> String {
        "api/v1/entities/\(rawValue)/\(id.uuidString.lowercased())"
    }
}

extension PlotChatCategory {
    var entityType: PlotEntityType {
        switch self {
        case .schedule: return .schedule
        case .task: return .task
        case .memo: return .memo
        }
    }
}

// MARK: - GET /entities

struct PlotGetEntitiesResponseDTO: Decodable, Sendable {
    let items: [PlotEntityListItemDTO]
    let nextCursor: String?
}

/// GET / PATCH / reclassify で共通の discriminated union 風 DTO。
/// Edge が狭い subset のみ返す場合も optional で吸収する。
struct PlotEntityListItemDTO: Codable, Sendable {
    let type: PlotEntityType
    let id: UUID
    let title: String
    let startAt: Date?
    let endAt: Date?
    let dueDate: Date?
    let isAllDay: Bool?
    let location: String?
    let notes: String?
    let content: String?
    let isCompleted: Bool?
    let isPinned: Bool?
    let priority: Int?
    let createdAt: Date?
    let updatedAt: Date?
}

// MARK: - PATCH /entities/{type}/{id}

struct PlotPatchEntityRequestDTO: Encodable, Sendable {
    var title: String?
    var startAt: Date?
    var endAt: Date?
    var dueDate: Date?
    var isAllDay: Bool?
    var location: String?
    var notes: String?
    var content: String?
    var isCompleted: Bool?
    var isPinned: Bool?
    var priority: Int?
}

struct PlotPatchEntityResponseDTO: Decodable, Sendable {
    let entity: PlotEntityListItemDTO
}

// MARK: - DELETE /entities/{type}/{id}

struct PlotDeleteEntityResponseDTO: Decodable, Sendable {
    let deleted: Bool
    let type: PlotEntityType
    let id: UUID
}

// MARK: - POST /chat/messages

struct PlotPostChatMessagesRequestDTO: Encodable, Sendable {
    let text: String
    let forcedCategory: PlotEntityType?
    let clientMessageId: String

    enum CodingKeys: String, CodingKey {
        case text
        case forcedCategory = "forced_category"
        case clientMessageId = "client_message_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        if let forcedCategory {
            try container.encode(forcedCategory, forKey: .forcedCategory)
        } else {
            try container.encodeNil(forKey: .forcedCategory)
        }
        try container.encode(clientMessageId, forKey: .clientMessageId)
    }
}

struct PlotPostChatMessagesResponseDTO: Decodable, Sendable {
    let messageId: UUID
    let assistantMessageId: UUID
    let confirmationText: String
    let createdEntities: [PlotCreatedEntityDTO]
}

struct PlotCreatedEntityDTO: Decodable, Sendable {
    let type: PlotEntityType
    let id: UUID
    let title: String
    let startAt: Date?
    let endAt: Date?
    let dueDate: Date?
    let isAllDay: Bool?
    let location: String?
    let notes: String?
    let content: String?
    let isCompleted: Bool?
    let isPinned: Bool?
    let priority: Int?
}

// MARK: - POST /chat/reclassify

struct PlotReclassifySourceDTO: Encodable, Sendable {
    let type: PlotEntityType
    let id: UUID
}

struct PlotPostReclassifyRequestDTO: Encodable, Sendable {
    let source: PlotReclassifySourceDTO
    let targetType: PlotEntityType
    let reasonText: String?
}

struct PlotPostReclassifyResponseDTO: Decodable, Sendable {
    let confirmationText: String
    let migratedEntity: PlotEntityListItemDTO
}

// MARK: - GET /chat/messages

enum PlotChatHistoryRole: String, Decodable, Sendable {
    case user
    case assistant
}

struct PlotGetChatMessagesResponseDTO: Decodable, Sendable {
    let items: [PlotChatHistoryMessageDTO]
}

struct PlotChatHistoryMessageDTO: Decodable, Sendable {
    let id: UUID
    let role: PlotChatHistoryRole
    let text: String
    let createdAt: Date
    let createdEntities: [PlotCreatedEntityDTO]?
}
