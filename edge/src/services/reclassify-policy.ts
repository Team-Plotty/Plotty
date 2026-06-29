import type { EntityReadModel, PersistenceRepository } from "./persistence.js";

/** `messages` の保持期間（720 時間 = 30 日）。docs/02, 09 と一致。 */
export const MESSAGE_RETENTION_MS = 720 * 60 * 60 * 1000;

export const RECLASSIFY_EXPIRED = "RECLASSIFY_EXPIRED";

export const reclassifyExpiredMessage =
  "元メッセージから30日経過したため、カテゴリを変更できません。";

const resolveReclassifyAnchorCreatedAt = async (
  repository: PersistenceRepository,
  userId: string,
  source: EntityReadModel
): Promise<string | null> => {
  if (source.sourceMessageId) {
    const message = await repository.findMessageById(userId, source.sourceMessageId);
    if (message) {
      return message.createdAt;
    }
  }
  return source.createdAt ?? null;
};

export const assertReclassifyAllowed = async (
  repository: PersistenceRepository,
  userId: string,
  source: EntityReadModel
): Promise<void> => {
  const anchorIso = await resolveReclassifyAnchorCreatedAt(repository, userId, source);
  if (!anchorIso) {
    return;
  }
  if (Date.now() - Date.parse(anchorIso) >= MESSAGE_RETENTION_MS) {
    throw new Error(RECLASSIFY_EXPIRED);
  }
};
