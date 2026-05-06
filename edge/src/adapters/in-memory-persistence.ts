import type {
  EntityReadFilter,
  EntityReadModel,
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
}

export const createInMemoryDatabase = (): InMemoryDatabase => ({
  messages: [],
  schedules: [],
  tasks: [],
  memos: []
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
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      startAt: item.startAt
    }));
    const tasks: EntityReadModel[] = db.tasks.map((item) => ({
      type: "task",
      id: item.id,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv,
      dueDate: item.dueDate
    }));
    const memos: EntityReadModel[] = db.memos.map((item) => ({
      type: "memo",
      id: item.id,
      titleEncrypted: item.titleEncrypted,
      iv: item.iv
    }));

    return [...schedules, ...tasks, ...memos]
      .filter((item) => (filter.type ? item.type === filter.type : true))
      .slice(0, filter.limit);
  }
});
