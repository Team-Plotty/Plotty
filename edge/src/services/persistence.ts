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
  createdAt?: string;
}

export interface MessageReadModel {
  id: string;
  userId: string;
  role: "user" | "assistant";
  contentEncrypted: string;
  iv: string;
  relatedEntities: RelatedEntityRef[];
  createdAt: string;
}

export interface MessageListFilter {
  userId: string;
  limit: number;
}

export interface BaseEntityWriteInput {
  id: string;
  userId: string;
  sourceMessageId: string | null;
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
  priority: 1 | 2 | 3;
  isCompleted: boolean;
}

export interface MemoWriteInput extends BaseEntityWriteInput {
  contentEncrypted: string;
  isPinned: boolean;
}

export interface EntityReadFilter {
  userId: string;
  type?: EntityType;
  limit: number;
}

export interface EntityReadModel {
  type: EntityType;
  id: string;
  userId: string;
  titleEncrypted: string;
  iv: string;
  originTextEncrypted?: string;
  startAt?: string;
  endAt?: string | null;
  isAllDay?: boolean;
  location?: string | null;
  dueDate?: string;
  isCompleted?: boolean;
  priority?: 1 | 2 | 3;
  contentEncrypted?: string;
  isPinned?: boolean;
  createdAt?: string;
  updatedAt?: string;
  isDeleted?: boolean;
}

export interface EntityUpdateInput {
  id: string;
  userId: string;
  type: EntityType;
  titleEncrypted?: string;
  titleHash?: string;
  iv?: string;
  originTextEncrypted?: string;
  startAt?: string;
  endAt?: string | null;
  isAllDay?: boolean;
  location?: string | null;
  dueDate?: string;
  isCompleted?: boolean;
  priority?: 1 | 2 | 3;
  contentEncrypted?: string;
  isPinned?: boolean;
}

export interface PersistenceRepository {
  insertMessage(input: MessageWriteInput): Promise<void>;
  updateMessageRelatedEntities(input: {
    id: string;
    userId: string;
    relatedEntities: RelatedEntityRef[];
  }): Promise<void>;
  insertSchedule(input: ScheduleWriteInput): Promise<void>;
  insertTask(input: TaskWriteInput): Promise<void>;
  insertMemo(input: MemoWriteInput): Promise<void>;
  findUserMessageByClientMessageId(
    userId: string,
    clientMessageId: string
  ): Promise<{
    id: string;
    relatedEntities: RelatedEntityRef[];
    analysisResultsEncrypted?: EncryptedPayload;
  } | null>;
  listEntities(filter: EntityReadFilter): Promise<EntityReadModel[]>;
  getEntityById(input: {
    userId: string;
    type: EntityType;
    id: string;
  }): Promise<EntityReadModel | null>;
  updateEntity(input: EntityUpdateInput): Promise<EntityReadModel | null>;
  softDeleteEntity(input: { id: string; userId: string; type: EntityType }): Promise<boolean>;
  replaceRelatedEntityRef(input: {
    userId: string;
    oldEntityId: string;
    newEntityId: string;
    newType: EntityType;
  }): Promise<void>;
  listMessages(filter: MessageListFilter): Promise<MessageReadModel[]>;
}

export interface BuildPersistenceInput {
  messageId: string;
  userId: string;
  clientMessageId: string;
  userPlainText: string;
  extraction: LlmExtractionResult;
  analysisResultsEncrypted: EncryptedPayload;
  textEncryption: EncryptedPayload;
  assistantTextEncryption: EncryptedPayload;
}
