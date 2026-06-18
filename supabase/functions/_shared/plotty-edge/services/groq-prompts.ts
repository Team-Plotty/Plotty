export interface ChatExtractionPromptContext {
  currentTimeIso: string;
  timezone: string;
  userId: string;
  forcedCategory: "schedule" | "task" | "memo" | null;
}

/** Groq json_object モード用: プロンプト内に json という語を含める */
export const CHAT_EXTRACTION_SYSTEM_PROMPT = `あなたは Plotty の AI アシスタントです。
ユーザー入力から予定・タスク・メモを抽出し、必ず次の json 形式のみを返してください。説明文や markdown は禁止です。

json スキーマ:
{
  "entities": [
    {
      "type": "schedule" | "task" | "memo",
      "data": {
        "title": "string (1-20文字)",
        "start_at": "ISO8601 (schedule のみ、任意)",
        "due_date": "ISO8601 (task のみ、任意)",
        "content": "string (memo 必須、task/schedule では本文)"
      }
    }
  ],
  "reply_message": "string (ユーザーへの確認メッセージ、1-1000文字)"
}

ルール:
- entities は 1 件以上
- schedule: start_at を timezone 基準で解釈
- task: due_date が無ければ省略可（サーバーが補完）
- memo: content に本文を入れる
- reply_message は friendly な日本語
- reply_message は必ず 1 文字以上（空文字禁止）
- schedule の data には start_at（ISO8601）を必ず含める。content は memo 向け`;

export const buildChatExtractionDeveloperPrompt = (
  context: ChatExtractionPromptContext
): string => {
  const forcedLine =
    context.forcedCategory === null
      ? "forced_category: null (AI が種別を推論)"
      : `forced_category: ${context.forcedCategory} (この種別で entities を 1 件生成)`;

  return [
    `current_time: ${context.currentTimeIso}`,
    `timezone: ${context.timezone}`,
    `user_id: ${context.userId}`,
    forcedLine
  ].join("\n");
};
