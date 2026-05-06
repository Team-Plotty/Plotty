import type { EntityType, LlmExtractionResult } from "../contracts/chat-messages.js";
import type { EncryptedPayload } from "./crypto.js";

export interface RelatedEntityRef {
  type: EntityType;
  id: string;
}

export interface MessageWriteInput {
  id: string;
  userId: string;
  role: "user" | "assistant";
  clientMessageId?: string;
  contentEncrypted: string;
  iv: string;
  relatedEntities: RelatedEntityRef[];
  analysisResultsEncrypted?: EncryptedPayload;
  expiresAt: string;
}

export interface BaseEntityWriteInput {
  id: string;
  userId: string;
  sourceMessageId: string;
  originTextEncrypted: string;
  titleEncrypted: string;
  titleHash: string;
  iv: string;
}

export interface ScheduleWriteInput extends BaseEntityWriteInput {
  startAt: string;
  endAt: string | null;
  isAllDay: boolean;
  location: string | null;
}

export interface TaskWriteInput extends BaseEntityWriteInput {
  dueDate: string;
  priority: 2 | 3 | 1;
}

export interface MemoWriteInput extends BaseEntityWriteInput {
  contentEncrypted: string;
}

export interface EntityReadFilter {
  userId: string;
  type?: EntityType;
  limit: number;
}

export interface EntityReadModel {
  type: EntityType;
  id: string;
  titleEncrypted: string;
  iv: string;
  startAt?: string;
  dueDate?: string;
}

export interface PersistenceRepository {
  insertMessage(input: MessageWriteInput): Promise<void>;
  insertSchedule(input: ScheduleWriteInput): Promise<void>;
  insertTask(input: TaskWriteInput): Promise<void>;
  insertMemo(input: MemoWriteInput): Promise<void>;
  listEntities(filter: EntityReadFilter): Promise<EntityReadModel[]>;
}

export interface BuildPersistenceInput {
  messageId: string;
  userId: string;
  clientMessageId: string;
  extraction: LlmExtractionResult;
  analysisResultsEncrypted: EncryptedPayload;
  textEncryption: EncryptedPayload;
  assistantTextEncryption: EncryptedPayload;
}
