import type { PostChatMessagesResponse } from "../contracts/chat-messages.ts";
import { llmExtractionResultSchema } from "../contracts/chat-messages.ts";
import type { CreatedEntityDto } from "../contracts/chat-messages.ts";
import type { CryptoService } from "./crypto.ts";
import {
  entityReadModelToDto,
  memoWriteToCreatedEntity,
  scheduleWriteToCreatedEntity,
  taskWriteToCreatedEntity
} from "./entity-dto-mapper.ts";
import type { PersistenceRepository } from "./persistence.ts";

interface StoredMessageRow {
  id: string;
  relatedEntities: Array<{ type: "schedule" | "task" | "memo"; id: string }>;
  analysisResultsEncrypted?: { iv: string; data: string };
}

export const rebuildChatResponseFromStoredMessage = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  userId: string,
  stored: StoredMessageRow
): Promise<PostChatMessagesResponse | null> => {
  if (!stored.analysisResultsEncrypted) {
    return null;
  }

  const analysisJson = await cryptoService.decryptText({
    iv: stored.analysisResultsEncrypted.iv,
    data: stored.analysisResultsEncrypted.data
  });
  const parsedAnalysis = llmExtractionResultSchema.safeParse(JSON.parse(analysisJson));
  if (!parsedAnalysis.success) {
    return null;
  }

  const createdEntities: CreatedEntityDto[] = [];
  for (const ref of stored.relatedEntities) {
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
    } else if (dto.type === "task") {
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
    } else {
      createdEntities.push(
        memoWriteToCreatedEntity(
          { id: dto.id, isPinned: dto.is_pinned },
          dto.title,
          dto.content
        )
      );
    }
  }

  return {
    message_id: stored.id,
    confirmation_text: parsedAnalysis.data.reply_message,
    created_entities: createdEntities
  };
};
