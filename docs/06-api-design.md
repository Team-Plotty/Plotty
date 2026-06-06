# 06. API設計書

## API責務

- クライアント: 入出力と表示
- Edge: 検証、暗号化/復号、Groq呼び出し、DB操作
- DB: 永続化とRLS

## Edge ランタイム

- **Supabase Edge Functions**（関数名: `plotty-api`）でホストする（`08` 意思決定ログ）。
- iOS は `https://<project-ref>.supabase.co/functions/v1/plotty-api/api/v1/...` に `Authorization: Bearer <access_token>` 付きで JSON リクエストする。
- Groq API キー・`service_role`・暗号鍵は **Edge Functions Secrets** のみ。クライアントに配布しない。
- 実装の正本: `edge/` の handler 契約 → デプロイ時は `supabase/functions/plotty-api/` に配置。

## 主要エンドポイント（MVP）

| メソッド | パス | 用途 |
|---|---|---|
| POST | `/api/v1/chat/messages` | 入力解析・`messages` + 実体作成 |
| POST | `/api/v1/chat/reclassify` | 実体の種別変更（論理削除 + 新規作成） |
| GET | `/api/v1/entities` | 一覧取得（`?type=` 任意。**MVP はこれのみ**） |
| PATCH | `/api/v1/schedules/{id}` | 予定更新 |
| PATCH | `/api/v1/tasks/{id}` | タスク更新 |
| PATCH | `/api/v1/memos/{id}` | メモ更新 |
| DELETE | `/api/v1/entities/{type}/{id}` | 論理削除 |

種別ごとの `GET /schedules` 等は **MVP では提供しない**（`08` / `docs/contracts/api-contract-mvp.md` §1）。

## I/O方針

- DBの暗号文をそのままUIへ返さない
- Edgeで復号後、表示用DTOとして返却（フィールド定義: `docs/contracts/api-contract-mvp.md` §2）
- `client_message_id` で冪等制御（**重複時は 200 + 初回レスポンス**。`docs/contracts/api-contract-mvp.md` §5）
