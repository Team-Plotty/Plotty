import type { EntityType } from "../contracts/chat-messages.js";
import type { CryptoService } from "./crypto.js";
import type {
  EntityReadModel,
  MemoWriteInput,
  PersistenceRepository,
  ScheduleWriteInput,
  TaskWriteInput
} from "./persistence.js";

export interface ReclassifyInput {
  userId: string;
  sourceType: EntityType;
  sourceId: string;
  targetType: EntityType;
}

export interface ReclassifyResult {
  confirmationText: string;
  migratedEntity: EntityReadModel;
}

const confirmationByTarget: Record<EntityType, string> = {
  schedule: "カレンダーに登録したよ！",
  task: "タスクに変更したよ！",
  memo: "メモに変更したよ！"
};

const hashTitle = async (title: string): Promise<string> => {
  const payload = new TextEncoder().encode(title);
  const digest = await crypto.subtle.digest("SHA-256", payload);
  const bytes = Array.from(new Uint8Array(digest));
  return bytes.map((byte) => byte.toString(16).padStart(2, "0")).join("");
};

const endOfDayIso = (baseDate: Date): string => {
  const date = new Date(baseDate);
  date.setUTCHours(23, 59, 59, 0);
  return date.toISOString();
};

const decryptTitle = async (cryptoService: CryptoService, entity: EntityReadModel): Promise<string> =>
  cryptoService.decryptText({ iv: entity.iv, data: entity.titleEncrypted });

const decryptOrigin = async (
  cryptoService: CryptoService,
  entity: EntityReadModel
): Promise<string> => {
  if (!entity.originTextEncrypted) {
    return "";
  }
  return cryptoService.decryptText({ iv: entity.iv, data: entity.originTextEncrypted });
};

const decryptContent = async (
  cryptoService: CryptoService,
  entity: EntityReadModel
): Promise<string> => {
  if (!entity.contentEncrypted) {
    return "";
  }
  return cryptoService.decryptText({ iv: entity.iv, data: entity.contentEncrypted });
};

export const reclassifyEntity = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  input: ReclassifyInput
): Promise<ReclassifyResult> => {
  const source = await repository.getEntityById({
    userId: input.userId,
    type: input.sourceType,
    id: input.sourceId
  });
  if (!source) {
    throw new Error("NOT_FOUND");
  }

  const title = await decryptTitle(cryptoService, source);
  const originText = await decryptOrigin(cryptoService, source);
  const contentText = await decryptContent(cryptoService, source);
  const titleEncryption = await cryptoService.encryptText(title);
  const originTextEncrypted = await cryptoService.encryptDataWithIv(
    originText || title,
    titleEncryption.iv
  );
  const titleHash = await hashTitle(title);
  const newId = crypto.randomUUID();

  let migratedEntity: EntityReadModel;

  if (input.targetType === "schedule") {
    const startAt =
      source.type === "schedule"
        ? (source.startAt ?? new Date().toISOString())
        : source.type === "task"
          ? (source.dueDate ?? new Date().toISOString())
          : new Date().toISOString();
    const schedule: ScheduleWriteInput = {
      id: newId,
      userId: input.userId,
      sourceMessageId: null,
      originTextEncrypted,
      titleEncrypted: titleEncryption.data,
      titleHash,
      iv: titleEncryption.iv,
      startAt,
      endAt: source.type === "schedule" ? (source.endAt ?? null) : null,
      isAllDay: source.type === "schedule" ? (source.isAllDay ?? false) : false,
      location: source.type === "schedule" ? (source.location ?? null) : null
    };
    await repository.insertSchedule(schedule);
    migratedEntity = {
      type: "schedule",
      id: newId,
      userId: input.userId,
      titleEncrypted: schedule.titleEncrypted,
      iv: schedule.iv,
      originTextEncrypted: schedule.originTextEncrypted,
      startAt: schedule.startAt,
      endAt: schedule.endAt,
      isAllDay: schedule.isAllDay,
      location: schedule.location,
      updatedAt: new Date().toISOString()
    };
  } else if (input.targetType === "task") {
    const dueDate =
      source.type === "task"
        ? (source.dueDate ?? endOfDayIso(new Date()))
        : source.type === "schedule"
          ? (source.startAt ?? endOfDayIso(new Date()))
          : endOfDayIso(new Date());
    const task: TaskWriteInput = {
      id: newId,
      userId: input.userId,
      sourceMessageId: null,
      originTextEncrypted,
      titleEncrypted: titleEncryption.data,
      titleHash,
      iv: titleEncryption.iv,
      dueDate,
      priority: source.type === "task" ? (source.priority ?? 2) : 2,
      isCompleted: source.type === "task" ? (source.isCompleted ?? false) : false
    };
    await repository.insertTask(task);
    migratedEntity = {
      type: "task",
      id: newId,
      userId: input.userId,
      titleEncrypted: task.titleEncrypted,
      iv: task.iv,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
      priority: task.priority,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  } else {
    const memoContent =
      source.type === "memo"
        ? contentText || title
        : originText || title;
    const contentEncrypted = await cryptoService.encryptDataWithIv(
      memoContent,
      titleEncryption.iv
    );
    const memo: MemoWriteInput = {
      id: newId,
      userId: input.userId,
      sourceMessageId: null,
      originTextEncrypted,
      titleEncrypted: titleEncryption.data,
      titleHash,
      iv: titleEncryption.iv,
      contentEncrypted,
      isPinned: source.type === "memo" ? (source.isPinned ?? false) : false
    };
    await repository.insertMemo(memo);
    migratedEntity = {
      type: "memo",
      id: newId,
      userId: input.userId,
      titleEncrypted: memo.titleEncrypted,
      iv: memo.iv,
      contentEncrypted: memo.contentEncrypted,
      isPinned: memo.isPinned,
      updatedAt: new Date().toISOString()
    };
  }

  const deleted = await repository.softDeleteEntity({
    id: input.sourceId,
    userId: input.userId,
    type: input.sourceType
  });
  if (!deleted) {
    throw new Error("NOT_FOUND");
  }

  await repository.replaceRelatedEntityRef({
    userId: input.userId,
    oldEntityId: input.sourceId,
    newEntityId: newId,
    newType: input.targetType
  });

  return {
    confirmationText: confirmationByTarget[input.targetType],
    migratedEntity
  };
};
