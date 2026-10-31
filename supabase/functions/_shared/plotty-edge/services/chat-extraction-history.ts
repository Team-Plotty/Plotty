import type { CryptoService } from "./crypto.ts";
import type { GroqHistoryMessage } from "./groq-client.ts";
import type { PersistenceRepository } from "./persistence.ts";

/** 問い返しへの答え（「15時です」など）を元の発言と結び付けられる程度の直近だけ渡す */
const HISTORY_MESSAGE_LIMIT = 6;
/** 時間が空いた古い会話を混ぜると、無関係な発言を答えと誤解しやすいため区切る */
const HISTORY_WINDOW_MS = 30 * 60 * 1000;

export const loadExtractionHistory = async (
  repository: PersistenceRepository,
  cryptoService: CryptoService,
  userId: string,
  now: Date
): Promise<GroqHistoryMessage[]> => {
  try {
    const rows = await repository.listRecentMessages({
      userId,
      limit: HISTORY_MESSAGE_LIMIT,
      since: new Date(now.getTime() - HISTORY_WINDOW_MS).toISOString()
    });
    return await Promise.all(
      rows.map(async (row) => ({
        role: row.role,
        content: await cryptoService.decryptText({ iv: row.iv, data: row.contentEncrypted })
      }))
    );
  } catch {
    // 履歴は抽出精度を上げる補助なので、読めなくても今回の発言だけで抽出を続ける
    return [];
  }
};
