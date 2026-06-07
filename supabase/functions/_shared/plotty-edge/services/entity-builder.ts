import type { LlmExtractionResult, PostChatMessagesResponse } from "../contracts/chat-messages.ts";
import type { CryptoService, EncryptedPayload } from "./crypto.ts";
import type { BuildPersistenceInput, MemoWriteInput, PersistenceRepository, RelatedEntityRef, ScheduleWriteInput, TaskWriteInput } from "./persistence.ts";

const addDays = (date: Date, days: number): Date => {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
};

const endOfDayIso = (baseDate: Date): string => {
  const date = new Date(baseDate);
  date.setUTCHours(23, 59, 59, 0);
  return date.toISOString();
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
  userMessageEncryption: EncryptedPayload,
  titleEncryption: EncryptedPayload,
  entity: LlmExtractionResult["entities"][number]
): Promise<ScheduleWriteInput> => {
  const startAt = entity.data.start_at ?? new Date().toISOString();

  return {
    id: crypto.randomUUID(),
    userId,
    sourceMessageId,
    originTextEncrypted: userMessageEncryption.data,
    titleEncrypted: titleEncryption.data,
    titleHash: await hashTitle(entity.data.title),
    iv: titleEncryption.iv,
    startAt,
    endAt: null,
    isAllDay: entity.data.start_at === undefined,
    location: null
  };
};

const buildTaskWriteInput = async (
  userId: string,
  sourceMessageId: string,
  userMessageEncryption: EncryptedPayload,
  titleEncryption: EncryptedPayload,
  entity: LlmExtractionResult["entities"][number]
): Promise<TaskWriteInput> => {
  return {
    id: crypto.randomUUID(),
    userId,
    sourceMessageId,
    originTextEncrypted: userMessageEncryption.data,
    titleEncrypted: titleEncryption.data,
    titleHash: await hashTitle(entity.data.title),
    iv: titleEncryption.iv,
    dueDate: entity.data.due_date ?? endOfDayIso(new Date()),
    priority: 2
  };
};

const buildMemoWriteInput = async (
  userId: string,
  sourceMessageId: string,
  userMessageEncryption: EncryptedPayload,
  titleEncryption: EncryptedPayload,
  contentEncryption: EncryptedPayload,
  entity: LlmExtractionResult["entities"][number]
): Promise<MemoWriteInput> => {
  return {
    id: crypto.randomUUID(),
    userId,
    sourceMessageId,
    originTextEncrypted: userMessageEncryption.data,
    titleEncrypted: titleEncryption.data,
    titleHash: await hashTitle(entity.data.title),
    iv: titleEncryption.iv,
    contentEncrypted: contentEncryption.data
  };
};

export const persistExtractionResults = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  input: BuildPersistenceInput
): Promise<PostChatMessagesResponse["created_entities"]> => {
  const relatedEntities: RelatedEntityRef[] = [];
  const createdEntities: PostChatMessagesResponse["created_entities"] = [];

  for (const entity of input.extraction.entities) {
    const titleEncryption = await cryptoService.encryptText(entity.data.title);

    if (entity.type === "schedule") {
      const schedule = await buildScheduleWriteInput(
        input.userId,
        input.messageId,
        input.textEncryption,
        titleEncryption,
        entity
      );
      await repository.insertSchedule(schedule);
      relatedEntities.push({ type: entity.type, id: schedule.id });
      createdEntities.push({
        type: entity.type,
        id: schedule.id,
        title: entity.data.title,
        start_at: schedule.startAt
      });
      continue;
    }

    if (entity.type === "task") {
      const task = await buildTaskWriteInput(
        input.userId,
        input.messageId,
        input.textEncryption,
        titleEncryption,
        entity
      );
      await repository.insertTask(task);
      relatedEntities.push({ type: entity.type, id: task.id });
      createdEntities.push({
        type: entity.type,
        id: task.id,
        title: entity.data.title,
        due_date: task.dueDate
      });
      continue;
    }

    const contentEncryption = await cryptoService.encryptText(entity.data.content);
    const memo = await buildMemoWriteInput(
      input.userId,
      input.messageId,
      input.textEncryption,
      titleEncryption,
      contentEncryption,
      entity
    );
    await repository.insertMemo(memo);
    relatedEntities.push({ type: entity.type, id: memo.id });
    createdEntities.push({
      type: entity.type,
      id: memo.id,
      title: entity.data.title
    });
  }

  await repository.insertMessage({
    id: input.messageId,
    userId: input.userId,
    role: "user",
    clientMessageId: input.clientMessageId,
    contentEncrypted: input.textEncryption.data,
    iv: input.textEncryption.iv,
    relatedEntities,
    analysisResultsEncrypted: input.analysisResultsEncrypted,
    expiresAt: addDays(new Date(), 30).toISOString()
  });

  await repository.insertMessage({
    id: crypto.randomUUID(),
    userId: input.userId,
    role: "assistant",
    contentEncrypted: input.assistantTextEncryption.data,
    iv: input.assistantTextEncryption.iv,
    relatedEntities,
    expiresAt: addDays(new Date(), 30).toISOString()
  });

  return createdEntities;
};
