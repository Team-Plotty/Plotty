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
        "start_at": "ISO8601 (schedule のみ。開始日時)",
        "end_at": "ISO8601 (schedule のみ、任意。終了日時)",
        "is_all_day": "boolean (schedule のみ。時刻の指定が無い予定なら true)",
        "due_date": "ISO8601 (task のみ、任意。締切日時)",
        "due_has_time": "boolean (task のみ。締切の時刻まで指定されていれば true)",
        "content": "string (memo 必須、task/schedule では本文)"
      }
    }
  ],
  "reply_message": "string (ユーザーへの確認メッセージ、1-1000文字)"
}

ルール:
- entities は 1 件以上
- 日時はすべて timezone 基準で解釈し、オフセット付き ISO8601 で返す
- schedule の data には start_at を必ず含める
- schedule:「10時から12時まで」のように終わりが分かれば end_at を入れる。終わりが無ければ end_at は省略
- schedule: 日付だけで時刻が無い予定は is_all_day を true にし、start_at はその日の 00:00:00 にする。時刻があれば is_all_day は false
- task: 締切が無ければ due_date と due_has_time は省略（サーバーが当日末を補完）
- task:「金曜18時までに」のように時刻があれば due_date にその日時を入れ due_has_time を true にする
- task: 日付だけなら due_date はその日の 23:59:59、due_has_time は false
- memo: content に本文を入れる
- reply_message は friendly な日本語
- reply_message は必ず 1 文字以上（空文字禁止）`;

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
