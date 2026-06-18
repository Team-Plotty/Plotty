import type {
  CreatedEntityDto,
  EntityDto,
  ScheduleEntityDto,
  TaskEntityDto,
  MemoEntityDto
} from "../contracts/chat-messages.js";
import { normalizeApiDateTime, normalizeApiDateTimeNullable } from "./api-datetime.js";
import type { CryptoService } from "./crypto.js";
import type { EntityReadModel } from "./persistence.js";

const decryptOptional = async (
  cryptoService: CryptoService,
  iv: string,
  data: string | undefined
): Promise<string> => {
  if (!data) {
    return "";
  }
  return cryptoService.decryptText({ iv, data });
};

export const entityReadModelToDto = async (
  cryptoService: CryptoService,
  readModel: EntityReadModel
): Promise<EntityDto> => {
  const title = await cryptoService.decryptText({
    iv: readModel.iv,
    data: readModel.titleEncrypted
  });

  if (readModel.type === "schedule") {
    const notes = await decryptOptional(
      cryptoService,
      readModel.iv,
      readModel.originTextEncrypted
    );
    return {
      type: "schedule",
      id: readModel.id,
      title,
      start_at: normalizeApiDateTime(readModel.startAt ?? new Date().toISOString()),
      end_at: normalizeApiDateTimeNullable(readModel.endAt ?? null),
      is_all_day: readModel.isAllDay ?? false,
      location: readModel.location ?? "",
      notes,
      updated_at: normalizeApiDateTime(readModel.updatedAt ?? new Date().toISOString())
    } satisfies ScheduleEntityDto;
  }

  if (readModel.type === "task") {
    return {
      type: "task",
      id: readModel.id,
      title,
      is_completed: readModel.isCompleted ?? false,
      due_date: normalizeApiDateTime(readModel.dueDate ?? new Date().toISOString()),
      priority: readModel.priority ?? 2,
      created_at: normalizeApiDateTime(readModel.createdAt ?? new Date().toISOString()),
      updated_at: normalizeApiDateTime(readModel.updatedAt ?? new Date().toISOString())
    } satisfies TaskEntityDto;
  }

  const content = await decryptOptional(
    cryptoService,
    readModel.iv,
    readModel.contentEncrypted
  );
  return {
    type: "memo",
    id: readModel.id,
    title,
    content,
    is_pinned: readModel.isPinned ?? false,
    updated_at: normalizeApiDateTime(readModel.updatedAt ?? new Date().toISOString())
  } satisfies MemoEntityDto;
};

export const scheduleWriteToCreatedEntity = (
  schedule: {
    id: string;
    startAt: string;
    endAt: string | null;
    isAllDay: boolean;
    location: string | null;
    originTextEncrypted: string;
  },
  title: string,
  notes: string
): CreatedEntityDto => ({
  type: "schedule",
  id: schedule.id,
  title,
  start_at: normalizeApiDateTime(schedule.startAt),
  end_at: normalizeApiDateTimeNullable(schedule.endAt),
  is_all_day: schedule.isAllDay,
  location: schedule.location ?? "",
  notes
});

export const taskWriteToCreatedEntity = (
  task: { id: string; dueDate: string; priority: 1 | 2 | 3; isCompleted: boolean },
  title: string
): CreatedEntityDto => ({
  type: "task",
  id: task.id,
  title,
  is_completed: task.isCompleted,
  due_date: normalizeApiDateTime(task.dueDate),
  priority: task.priority
});

export const memoWriteToCreatedEntity = (
  memo: { id: string; isPinned: boolean },
  title: string,
  content: string
): CreatedEntityDto => ({
  type: "memo",
  id: memo.id,
  title,
  content,
  is_pinned: memo.isPinned
});
