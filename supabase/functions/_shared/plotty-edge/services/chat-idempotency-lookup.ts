import type { PostChatMessagesResponse } from "../contracts/chat-messages.ts";
import type { CryptoService } from "./crypto.ts";
import { rebuildChatResponseFromStoredMessage } from "./chat-idempotency.ts";
import type { PersistenceRepository } from "./persistence.ts";

export const findIdempotentChatResponse = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  userId: string,
  clientMessageId: string
): Promise<PostChatMessagesResponse | null> => {
  const stored = await repository.findUserMessageByClientMessageId(userId, clientMessageId);
  if (!stored) {
    return null;
  }
  return rebuildChatResponseFromStoredMessage(repository, cryptoService, userId, stored);
};
