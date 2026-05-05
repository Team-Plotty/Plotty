# 05. AI/Groqとプロンプト方針

## 利用範囲

- 入力文の構造化抽出（日時、タイトル、カテゴリ）
- チャット応答生成
- 再分類リクエストの解釈

## モデル運用

- 本番: `llama-3.1-70b-versatile`（精度重視）
- 開発: `llama-3.1-8b-instant`（高速重視）
- タイムアウト: 10秒
- リトライ: 最大1回

## 呼び出し経路

- APIキーはEdgeのみ保持
- クライアントはJWT付きでEdgeを呼ぶ

## `ai_persona_config`（MVP）

```json
{
  "name": "Plotty",
  "tone": "friendly",
  "identity": "優秀な秘書",
  "prohibited_topics": ["politics", "religion"]
}
```

- LLMに送るのは会話制御に必要な項目のみ
- `id` / `user_id` / `updated_at` など管理項目は送らない
