import type {
  EntityReadFilter,
  EntityReadModel,
  EntityUpdateInput,
  MemoWriteInput,
  MessageWriteInput,
  PersistenceRepository,
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

export const createInMemoryPersistenceRepository = (
  db: InMemoryDatabase
): PersistenceRepository => ({
  async insertMessage(input: MessageWriteInput): Promise<void> {
    db.messages.push(input);
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
  async listEntities(filter: EntityReadFilter): Promise<EntityReadModel[]> {
    const schedules: EntityReadModel[] = db.schedules.map((item) => ({
      type: "schedule",
      id: item.id,
      userId: item.userId,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      startAt: item.startAt,
      isDeleted: db.deletedEntityIds.has(item.id)
    }));
    const tasks: EntityReadModel[] = db.tasks.map((item) => ({
      type: "task",
      id: item.id,
      userId: item.userId,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      dueDate: item.dueDate,
      isDeleted: db.deletedEntityIds.has(item.id)
    }));
    const memos: EntityReadModel[] = db.memos.map((item) => ({
      type: "memo",
      id: item.id,
      userId: item.userId,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      contentEncrypted: item.contentEncrypted,
      isDeleted: db.deletedEntityIds.has(item.id)
    }));

    return [...schedules, ...tasks, ...memos]
      .filter((item) => item.userId === filter.userId)
      .filter((item) => !item.isDeleted)
      .filter((item) => (filter.type ? item.type === filter.type : true))
      .slice(0, filter.limit);
  },
  async updateEntity(input: EntityUpdateInput): Promise<EntityReadModel | null> {
    if (input.type === "schedule") {
      const found = db.schedules.find((item) => item.id === input.id && item.userId === input.userId);
      if (!found || db.deletedEntityIds.has(found.id)) return null;
      if (input.titleEncrypted) found.titleEncrypted = input.titleEncrypted;
      if (input.iv) found.iv = input.iv;
      if (input.startAt) found.startAt = input.startAt;
      return {
        type: "schedule",
        id: found.id,
        userId: found.userId,
        titleEncrypted: found.titleEncrypted,
        iv: found.iv,
        startAt: found.startAt
      };
    }

    if (input.type === "task") {
      const found = db.tasks.find((item) => item.id === input.id && item.userId === input.userId);
      if (!found || db.deletedEntityIds.has(found.id)) return null;
      if (input.titleEncrypted) found.titleEncrypted = input.titleEncrypted;
      if (input.iv) found.iv = input.iv;
      if (input.dueDate) found.dueDate = input.dueDate;
      return {
        type: "task",
        id: found.id,
        userId: found.userId,
        titleEncrypted: found.titleEncrypted,
        iv: found.iv,
        dueDate: found.dueDate
      };
    }

    const found = db.memos.find((item) => item.id === input.id && item.userId === input.userId);
    if (!found || db.deletedEntityIds.has(found.id)) return null;
    if (input.titleEncrypted) found.titleEncrypted = input.titleEncrypted;
    if (input.iv) found.iv = input.iv;
    if (input.contentEncrypted) found.contentEncrypted = input.contentEncrypted;
    return {
      type: "memo",
      id: found.id,
      userId: found.userId,
      titleEncrypted: found.titleEncrypted,
      iv: found.iv,
      contentEncrypted: found.contentEncrypted
    };
  },
  async softDeleteEntity(input: { id: string; userId: string; type: "schedule" | "task" | "memo" }): Promise<boolean> {
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
  }
});
