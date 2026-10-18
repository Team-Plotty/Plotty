import type { PostChatMessagesResponse } from "../contracts/chat-messages.js";
import type { LlmExtractionResult } from "../contracts/chat-messages.js";
import { endOfDayInTimeZoneIso } from "./api-datetime.js";
import type { CryptoService, EncryptedPayload } from "./crypto.js";
import {
  memoWriteToCreatedEntity,
  scheduleWriteToCreatedEntity,
  taskWriteToCreatedEntity
} from "./entity-dto-mapper.js";
import type {
  BuildPersistenceInput,
  MemoWriteInput,
  PersistenceRepository,
  RelatedEntityRef,
  ScheduleWriteInput,
  TaskWriteInput
} from "./persistence.js";

const addDays = (date: Date, days: number): Date => {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
};

const hashTitle = async (title: string): Promise<string> => {
  const payload = new TextEncoder().encode(title);
  const digest = await crypto.subtle.digest("SHA-256", payload);
  const bytes = Array.from(new Uint8Array(digest));
  return bytes.map((byte) => byte.toString(16).padStart(2, "0")).join("");
};

const buildScheduleWriteInput = async (
  userId: string,
  sourceMessageId: string,
  originTextEncrypted: string,
  titleEncryption: EncryptedPayload,
  entity: LlmExtractionResult["entities"][number]
): Promise<ScheduleWriteInput> => {
  const startAt = entity.data.start_at ?? new Date().toISOString();
  const isAllDay = entity.data.is_all_day ?? entity.data.start_at === undefined;
  const endAt = entity.data.end_at;
  // 終日なら終了は不要。開始以前の終了は抽出ミスとして捨て、クライアントの既定（開始＋1時間）に任せる
  const validEndAt =
    !isAllDay && endAt !== undefined && Date.parse(endAt) > Date.parse(startAt) ? endAt : null;

  return {
    id: crypto.randomUUID(),
    userId,
    sourceMessageId,
    originTextEncrypted,
    titleEncrypted: titleEncryption.data,
    titleHash: await hashTitle(entity.data.title),
    iv: titleEncryption.iv,
    startAt,
    endAt: validEndAt,
    isAllDay,
    location: null
  };
};

const buildTaskWriteInput = async (
  userId: string,
  sourceMessageId: string,
  originTextEncrypted: string,
  titleEncryption: EncryptedPayload,
  entity: LlmExtractionResult["entities"][number],
  timezone: string
): Promise<TaskWriteInput> => {
  const dueDate = entity.data.due_date;
  return {
    id: crypto.randomUUID(),
    userId,
    sourceMessageId,
    originTextEncrypted,
    titleEncrypted: titleEncryption.data,
    titleHash: await hashTitle(entity.data.title),
    iv: titleEncryption.iv,
    dueDate: dueDate ?? endOfDayInTimeZoneIso(new Date(), timezone),
    dueHasTime: dueDate !== undefined && (entity.data.due_has_time ?? false),
    priority: 2,
    isCompleted: false
  };
};

const buildMemoWriteInput = async (
  userId: string,
  sourceMessageId: string,
  originTextEncrypted: string,
  titleEncryption: EncryptedPayload,
  contentEncrypted: string,
  entity: LlmExtractionResult["entities"][number]
): Promise<MemoWriteInput> => {
  return {
    id: crypto.randomUUID(),
    userId,
    sourceMessageId,
    originTextEncrypted,
    titleEncrypted: titleEncryption.data,
    titleHash: await hashTitle(entity.data.title),
    iv: titleEncryption.iv,
    contentEncrypted,
    isPinned: false
  };
};

export const persistExtractionResults = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  input: BuildPersistenceInput
): Promise<{
  createdEntities: PostChatMessagesResponse["created_entities"];
  assistantMessageId: string;
}> => {
  const relatedEntities: RelatedEntityRef[] = [];
  const createdEntities: PostChatMessagesResponse["created_entities"] = [];

  await repository.insertMessage({
    id: input.messageId,
    userId: input.userId,
    role: "user",
    clientMessageId: input.clientMessageId,
    contentEncrypted: input.textEncryption.data,
    iv: input.textEncryption.iv,
    relatedEntities: [],
    analysisResultsEncrypted: input.analysisResultsEncrypted,
    expiresAt: addDays(new Date(), 30).toISOString()
  });

  for (const entity of input.extraction.entities) {
    const titleEncryption = await cryptoService.encryptText(entity.data.title);
    const originTextEncrypted = await cryptoService.encryptDataWithIv(
      input.userPlainText,
      titleEncryption.iv
    );

    if (entity.type === "schedule") {
      const schedule = await buildScheduleWriteInput(
        input.userId,
        input.messageId,
        originTextEncrypted,
        titleEncryption,
        entity
      );
      await repository.insertSchedule(schedule);
      relatedEntities.push({ type: entity.type, id: schedule.id });
      const notes = input.userPlainText;
      createdEntities.push(
        scheduleWriteToCreatedEntity(schedule, entity.data.title, notes)
      );
      continue;
    }

    if (entity.type === "task") {
      const task = await buildTaskWriteInput(
        input.userId,
        input.messageId,
        originTextEncrypted,
        titleEncryption,
        entity,
        input.timezone
      );
      await repository.insertTask(task);
      relatedEntities.push({ type: entity.type, id: task.id });
      createdEntities.push(taskWriteToCreatedEntity(task, entity.data.title));
      continue;
    }

    const contentPlain = entity.data.content ?? entity.data.title;
    const contentEncrypted = await cryptoService.encryptDataWithIv(
      contentPlain,
      titleEncryption.iv
    );
    const memo = await buildMemoWriteInput(
      input.userId,
      input.messageId,
      originTextEncrypted,
      titleEncryption,
      contentEncrypted,
      entity
    );
    await repository.insertMemo(memo);
    relatedEntities.push({ type: entity.type, id: memo.id });
    createdEntities.push(
      memoWriteToCreatedEntity(memo, entity.data.title, contentPlain)
    );
  }

  await repository.updateMessageRelatedEntities({
    id: input.messageId,
    userId: input.userId,
    relatedEntities
  });

  const assistantMessageId = crypto.randomUUID();
  await repository.insertMessage({
    id: assistantMessageId,
    userId: input.userId,
    role: "assistant",
    contentEncrypted: input.assistantTextEncryption.data,
    iv: input.assistantTextEncryption.iv,
    relatedEntities,
    expiresAt: addDays(new Date(), 30).toISOString()
  });

  return { createdEntities, assistantMessageId };
};
