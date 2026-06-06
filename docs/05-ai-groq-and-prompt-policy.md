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

- APIキーは **Supabase Edge Functions**（`plotty-api`）のみ保持
- クライアントは JWT 付きで Edge Functions URL を呼ぶ

## 利用量制限（MVP）

Plotty は **大量利用を前提としない**（個人〜小規模）。コスト暴走・誤ループ・悪用の保険として、**ユーザー単位の1日トークン上限**を Edge で enforce する。

| 項目 | 方針 |
|---|---|
| 単位 | `user_id`（Supabase JWT） |
| 集計 | Groq 応答の `usage`（prompt + completion）を **1 リクエスト成功ごとに加算** |
| リセット | **UTC 0:00**（日次） |
| MVP 初期値 | **50,000 tokens / user / day**（様子見で調整可。厳しすぎない安全弁） |
| 超過時 | HTTP 429 + `RATE_LIMITED`。UI は「本日の AI 利用上限に達しました。明日再度お試しください。」 |
| 対象 API | `POST /chat/messages`、将来の `POST /chat/reclassify`（Groq を呼ぶ経路のみ） |
| 非対象 | `GET /entities`、PATCH / DELETE（Groq 不使用） |

**補助制限（既存）:** 短時間の連打防止として **60 req / 60s / user**（`RATE_LIMIT_*`）を chat 系に併用してよい。日次トークン上限と役割が異なる。

**実装メモ:** 日次集計は Supabase Edge Function 内で **`user_daily_groq_usage` テーブル**（PostgreSQL）に記録する。in-memory のみではインスタンス跨ぎで抜けるため本番不可。

**運用:** Groq ダッシュボードのアカウント全体使用量も週次で確認。上限は env で変更可能にし、後悔しない範囲で開始 → 必要なら引き下げる。

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
