import type {
  EntityReadFilter,
  EntityReadModel,
  EntityUpdateInput,
  MemoWriteInput,
  MessageListFilter,
  MessageReadModel,
  MessageWriteInput,
  PersistenceRepository,
  RelatedEntityRef,
  ScheduleWriteInput,
  TaskWriteInput
} from "../services/persistence.js";

export interface InMemoryDatabase {
  messages: MessageWriteInput[];
  schedules: ScheduleWriteInput[];
  tasks: TaskWriteInput[];
  memos: MemoWriteInput[];
  deletedEntityIds: Set<string>;
}

export const createInMemoryDatabase = (): InMemoryDatabase => ({
  messages: [],
  schedules: [],
  tasks: [],
  memos: [],
  deletedEntityIds: new Set<string>()
});

const nowIso = (): string => new Date().toISOString();

export const createInMemoryPersistenceRepository = (
  db: InMemoryDatabase
): PersistenceRepository => ({
  async insertMessage(input: MessageWriteInput): Promise<void> {
    db.messages.push({
      ...input,
      createdAt: input.createdAt ?? nowIso()
    });
  },
  async updateMessageRelatedEntities(input: {
    id: string;
    userId: string;
    relatedEntities: RelatedEntityRef[];
  }): Promise<void> {
    const found = db.messages.find((message) => message.id === input.id && message.userId === input.userId);
    if (found) {
      found.relatedEntities = input.relatedEntities;
    }
  },
  async insertSchedule(input: ScheduleWriteInput): Promise<void> {
    db.schedules.push(input);
  },
  async insertTask(input: TaskWriteInput): Promise<void> {
    db.tasks.push(input);
  },
  async insertMemo(input: MemoWriteInput): Promise<void> {
    db.memos.push(input);
  },
  async findUserMessageByClientMessageId(userId: string, clientMessageId: string) {
    const found = db.messages.find(
      (message) =>
        message.userId === userId &&
        message.role === "user" &&
        message.clientMessageId === clientMessageId &&
        message.analysisResultsEncrypted
    );
    if (!found?.analysisResultsEncrypted) return null;
    return {
      id: found.id,
      relatedEntities: found.relatedEntities,
      analysisResultsEncrypted: found.analysisResultsEncrypted
    };
  },
  async listEntities(filter: EntityReadFilter): Promise<EntityReadModel[]> {
    const timestamp = nowIso();
    const schedules: EntityReadModel[] = db.schedules.map((item, index) => ({
      type: "schedule" as const,
      id: item.id,
      userId: item.userId,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      originTextEncrypted: item.originTextEncrypted,
      startAt: item.startAt,
      endAt: item.endAt,
      isAllDay: item.isAllDay,
      location: item.location,
      updatedAt: new Date(Date.now() - index * 1000).toISOString(),
      isDeleted: db.deletedEntityIds.has(item.id)
    }));
    const tasks: EntityReadModel[] = db.tasks.map((item, index) => ({
      type: "task" as const,
      id: item.id,
      userId: item.userId,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      dueDate: item.dueDate,
      isCompleted: item.isCompleted,
      priority: item.priority,
      createdAt: timestamp,
      updatedAt: new Date(Date.now() - (index + 100) * 1000).toISOString(),
      isDeleted: db.deletedEntityIds.has(item.id)
    }));
    const memos: EntityReadModel[] = db.memos.map((item, index) => ({
      type: "memo" as const,
      id: item.id,
      userId: item.userId,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      contentEncrypted: item.contentEncrypted,
      isPinned: item.isPinned,
      updatedAt: new Date(Date.now() - (index + 200) * 1000).toISOString(),
      isDeleted: db.deletedEntityIds.has(item.id)
    }));

    return [...schedules, ...tasks, ...memos]
      .filter((item) => item.userId === filter.userId)
      .filter((item) => !item.isDeleted)
      .filter((item) => (filter.type ? item.type === filter.type : true))
      .sort((a, b) => Date.parse(b.updatedAt ?? "0") - Date.parse(a.updatedAt ?? "0"))
      .slice(0, filter.limit);
  },
  async getEntityById(input: {
    userId: string;
    type: "schedule" | "task" | "memo";
    id: string;
  }): Promise<EntityReadModel | null> {
    const timestamp = nowIso();
    if (input.type === "schedule") {
      const found = db.schedules.find(
        (item) => item.id === input.id && item.userId === input.userId
      );
      if (!found || db.deletedEntityIds.has(found.id)) return null;
      return {
        type: "schedule",
        id: found.id,
        userId: found.userId,
        titleEncrypted: found.titleEncrypted,
        iv: found.iv,
        originTextEncrypted: found.originTextEncrypted,
        startAt: found.startAt,
        endAt: found.endAt,
        isAllDay: found.isAllDay,
        location: found.location,
        updatedAt: timestamp
      };
    }
    if (input.type === "task") {
      const found = db.tasks.find((item) => item.id === input.id && item.userId === input.userId);
      if (!found || db.deletedEntityIds.has(found.id)) return null;
      return {
        type: "task",
        id: found.id,
        userId: found.userId,
        titleEncrypted: found.titleEncrypted,
        iv: found.iv,
        dueDate: found.dueDate,
        isCompleted: found.isCompleted,
        priority: found.priority,
        createdAt: timestamp,
        updatedAt: timestamp
      };
    }
    const found = db.memos.find((item) => item.id === input.id && item.userId === input.userId);
    if (!found || db.deletedEntityIds.has(found.id)) return null;
    return {
      type: "memo",
      id: found.id,
      userId: found.userId,
      titleEncrypted: found.titleEncrypted,
      iv: found.iv,
      contentEncrypted: found.contentEncrypted,
      isPinned: found.isPinned,
      updatedAt: timestamp
    };
  },
  async updateEntity(input: EntityUpdateInput): Promise<EntityReadModel | null> {
    if (input.type === "schedule") {
      const found = db.schedules.find((item) => item.id === input.id && item.userId === input.userId);
      if (!found || db.deletedEntityIds.has(found.id)) return null;
      if (input.titleEncrypted) found.titleEncrypted = input.titleEncrypted;
      if (input.titleHash) found.titleHash = input.titleHash;
      if (input.iv) found.iv = input.iv;
      if (input.originTextEncrypted) found.originTextEncrypted = input.originTextEncrypted;
      if (input.startAt) found.startAt = input.startAt;
      if (input.endAt !== undefined) found.endAt = input.endAt;
      if (input.isAllDay !== undefined) found.isAllDay = input.isAllDay;
      if (input.location !== undefined) found.location = input.location;
      return {
        type: "schedule",
        id: found.id,
        userId: found.userId,
        titleEncrypted: found.titleEncrypted,
        iv: found.iv,
        originTextEncrypted: found.originTextEncrypted,
        startAt: found.startAt,
        endAt: found.endAt,
        isAllDay: found.isAllDay,
        location: found.location,
        updatedAt: nowIso()
      };
    }

    if (input.type === "task") {
      const found = db.tasks.find((item) => item.id === input.id && item.userId === input.userId);
      if (!found || db.deletedEntityIds.has(found.id)) return null;
      if (input.titleEncrypted) found.titleEncrypted = input.titleEncrypted;
      if (input.titleHash) found.titleHash = input.titleHash;
      if (input.iv) found.iv = input.iv;
      if (input.dueDate) found.dueDate = input.dueDate;
      if (input.isCompleted !== undefined) found.isCompleted = input.isCompleted;
      if (input.priority !== undefined) found.priority = input.priority;
      return {
        type: "task",
        id: found.id,
        userId: found.userId,
        titleEncrypted: found.titleEncrypted,
        iv: found.iv,
        dueDate: found.dueDate,
        isCompleted: found.isCompleted,
        priority: found.priority,
        createdAt: nowIso(),
        updatedAt: nowIso()
      };
    }

    const found = db.memos.find((item) => item.id === input.id && item.userId === input.userId);
    if (!found || db.deletedEntityIds.has(found.id)) return null;
    if (input.titleEncrypted) found.titleEncrypted = input.titleEncrypted;
    if (input.titleHash) found.titleHash = input.titleHash;
    if (input.iv) found.iv = input.iv;
    if (input.contentEncrypted) found.contentEncrypted = input.contentEncrypted;
    if (input.isPinned !== undefined) found.isPinned = input.isPinned;
    return {
      type: "memo",
      id: found.id,
      userId: found.userId,
      titleEncrypted: found.titleEncrypted,
      iv: found.iv,
      contentEncrypted: found.contentEncrypted,
      isPinned: found.isPinned,
      updatedAt: nowIso()
    };
  },
  async softDeleteEntity(input: {
    id: string;
    userId: string;
    type: "schedule" | "task" | "memo";
  }): Promise<boolean> {
    const rows =
      input.type === "schedule"
        ? db.schedules
        : input.type === "task"
          ? db.tasks
          : db.memos;
    const exists = rows.some((item) => item.id === input.id && item.userId === input.userId);
    if (!exists) {
      return false;
    }
    db.deletedEntityIds.add(input.id);
    return true;
  },
  async replaceRelatedEntityRef(input: {
    userId: string;
    oldEntityId: string;
    newEntityId: string;
    newType: "schedule" | "task" | "memo";
  }): Promise<void> {
    for (const message of db.messages) {
      if (message.userId !== input.userId) continue;
      const index = message.relatedEntities.findIndex((item) => item.id === input.oldEntityId);
      if (index < 0) continue;
      message.relatedEntities[index] = { type: input.newType, id: input.newEntityId };
    }
  },
  async listMessages(filter: MessageListFilter): Promise<MessageReadModel[]> {
    return db.messages
      .filter((message) => message.userId === filter.userId)
      .sort(
        (left, right) =>
          Date.parse(left.createdAt ?? "") - Date.parse(right.createdAt ?? "")
      )
      .slice(0, filter.limit)
      .map((message) => ({
        id: message.id,
        userId: message.userId,
        role: message.role,
        contentEncrypted: message.contentEncrypted,
        iv: message.iv,
        relatedEntities: message.relatedEntities,
        createdAt: message.createdAt ?? nowIso()
      }));
  }
});
