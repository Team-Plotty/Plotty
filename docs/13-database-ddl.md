# 13. データベース DDL

## 正本となる SQL

| ファイル | 内容 |
|---------|------|
| [`edge/sql/plotty_schema.sql`](../edge/sql/plotty_schema.sql) | **テーブル／インデックス／RLS／`updated_at` トリガー** の一式（SQL 正本） |
| [`supabase/migrations/20260603120000_plotty_schema.sql`](../supabase/migrations/20260603120000_plotty_schema.sql) | 上記を **Supabase migration** 化したもの（A1） |
| [`edge/sql/messages-retention-job.sql`](../edge/sql/messages-retention-job.sql) | **`messages` 30日削除** の `pg_cron` 登録（UTC・720時間） |

仕様の根拠: `09-implementation-spec-detailed.md`。

## 適用の推奨順序

**リモート / ローカル Supabase（推奨）**

1. `supabase link --project-ref <ref>` のあと `supabase db push` で `20260603120000_plotty_schema.sql` を適用
2. Edge Functions ローカル開発時は `supabase/.env.example` を `supabase/.env.local` にコピーして Secrets を設定（`09` §10.2）
3. `auth.users` → `public.users` 連携トリガー（A2 migration）
4. `messages-retention-job.sql`（A3 migration、`pg_cron` 拡張が有効であること）

**手動 SQL（参考）**

1. `plotty_schema.sql`（スキーマ本体）
2. 上記 2・3 と同順

## 対象テーブル

- `public.users` — `auth.users` と 1 対 1
- `public.messages` — 対話ログ（`related_entities` / `analysis_results_encrypted`、`expires_at` は `created_at + 720時間` を **BEFORE INSERT トリガー**で設定。※`timestamptz` の GENERATED 式は環境により `generation expression is not immutable` で失敗するため生成列にはしない）
- `public.schedules` / `public.tasks` / `public.memos` — 共通暗号列 + 種別ごとの列

## RLS（本 DDL に含む内容）

- `auth.uid() = user_id` の本人データのみ（`users` は `id = auth.uid()`）
- `messages` は **SELECT / INSERT のみ**（更新・削除はクライアント JWT では不可。バッチ・Edge の `service_role` で実施する想定）

## 注意事項

- 本 DDL は初回作成用。運用では **Supabase migration** などに移し、重複実行時の `CREATE POLICY` 衝突には `DROP POLICY IF EXISTS` の整備を推奨する。
- メッセージの物理削除ジョブは **必ず `service_role` 相当の権限**で動かす（RLS バイパスが必要なため）。

## 今後の migration（施工待ち）

`plotty_schema.sql` 適用**後**、別 migration で追加予定。設計詳細: `docs/contracts/implementation-notes.md` §3。

| 追加対象 | 用途 |
|---|---|
| `messages.client_message_id` | チャット POST 冪等 |
| `public.user_daily_groq_usage` | Groq 日次トークン上限（user × UTC 日付） |
