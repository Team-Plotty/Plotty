import type { CreatedEntityDto } from "../contracts/chat-messages.ts";
import type { CryptoService } from "./crypto.ts";
import {
  entityReadModelToDto,
  memoWriteToCreatedEntity,
  scheduleWriteToCreatedEntity,
  taskWriteToCreatedEntity
} from "./entity-dto-mapper.ts";
import type { MessageReadModel, PersistenceRepository, RelatedEntityRef } from "./persistence.ts";

export const buildCreatedEntitiesFromRefs = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  userId: string,
  refs: RelatedEntityRef[]
): Promise<CreatedEntityDto[]> => {
  const createdEntities: CreatedEntityDto[] = [];

  for (const ref of refs) {
    const entity = await repository.getEntityById({
      userId,
      type: ref.type,
      id: ref.id
    });
    if (!entity) continue;

    const dto = await entityReadModelToDto(cryptoService, entity);
    if (dto.type === "schedule") {
      createdEntities.push(
        scheduleWriteToCreatedEntity(
          {
            id: dto.id,
            startAt: dto.start_at,
            endAt: dto.end_at,
            isAllDay: dto.is_all_day,
            location: dto.location,
            originTextEncrypted: ""
          },
          dto.title,
          dto.notes
        )
      );
      continue;
    }

    if (dto.type === "task") {
      createdEntities.push(
        taskWriteToCreatedEntity(
          {
            id: dto.id,
            dueDate: dto.due_date,
            priority: dto.priority as 1 | 2 | 3,
            isCompleted: dto.is_completed
          },
          dto.title
        )
      );
      continue;
    }

    createdEntities.push(
      memoWriteToCreatedEntity(
        { id: dto.id, isPinned: dto.is_pinned },
        dto.title,
        dto.content
      )
    );
  }

  return createdEntities;
};

export const findAssistantMessageIdAfterUser = (
  messages: MessageReadModel[],
  userMessageId: string
): string | undefined => {
  const userIndex = messages.findIndex((message) => message.id === userMessageId);
  if (userIndex < 0) return undefined;
  const next = messages[userIndex + 1];
  return next?.role === "assistant" ? next.id : undefined;
};

export const toChatHistoryMessage = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  userId: string,
  row: MessageReadModel
): Promise<{
  id: string;
  role: "user" | "assistant";
  text: string;
  created_at: string;
  created_entities?: CreatedEntityDto[];
}> => {
  const text = await cryptoService.decryptText({
    iv: row.iv,
    data: row.contentEncrypted
  });

  if (row.role === "assistant" && row.relatedEntities.length > 0) {
    const created_entities = await buildCreatedEntitiesFromRefs(
      repository,
      cryptoService,
      userId,
      row.relatedEntities
    );
    return {
      id: row.id,
      role: row.role,
      text,
      created_at: row.createdAt,
      created_entities: created_entities.length > 0 ? created_entities : undefined
    };
  }

  return {
    id: row.id,
    role: row.role,
    text,
    created_at: row.createdAt
  };
};
