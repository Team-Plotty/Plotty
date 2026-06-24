import type { PostChatMessagesResponse } from "../contracts/chat-messages.js";
import type { CryptoService } from "./crypto.js";
import { rebuildChatResponseFromStoredMessage } from "./chat-idempotency.js";
import type { PersistenceRepository } from "./persistence.js";

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
