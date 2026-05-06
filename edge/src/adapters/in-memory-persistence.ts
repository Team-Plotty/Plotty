import type {
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
  }
});
