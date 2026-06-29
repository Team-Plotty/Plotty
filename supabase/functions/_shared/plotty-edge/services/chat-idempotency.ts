import type { PostChatMessagesResponse } from "../contracts/chat-messages.ts";
import { llmExtractionResultSchema } from "../contracts/chat-messages.ts";
import type { CryptoService } from "./crypto.ts";
import {
  buildCreatedEntitiesFromRefs,
  findAssistantMessageIdAfterUser
} from "./chat-history.ts";
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

  const createdEntities = await buildCreatedEntitiesFromRefs(
    repository,
    cryptoService,
    userId,
    stored.relatedEntities
  );

  const allMessages = await repository.listMessages({ userId, limit: 200 });
  const assistantMessageId = findAssistantMessageIdAfterUser(allMessages, stored.id);
  if (!assistantMessageId) {
    return null;
  }

  return {
    message_id: stored.id,
    assistant_message_id: assistantMessageId,
    confirmation_text: parsedAnalysis.data.reply_message,
    created_entities: createdEntities
  };
};
