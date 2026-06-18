# 13. データベース DDL

## 正本となる SQL

| ファイル | 内容 |
|---------|------|
| [`edge/sql/plotty_schema.sql`](../edge/sql/plotty_schema.sql) | **テーブル／インデックス／トリガー** の一式（SQL 正本。RLS は別ファイル） |
| [`edge/sql/rls-policies.sql`](../edge/sql/rls-policies.sql) | **RLS ポリシー** の SQL 正本 |
| [`supabase/migrations/20260603120000_plotty_schema.sql`](../supabase/migrations/20260603120000_plotty_schema.sql) | スキーマ + 初回 RLS（A1） |
| [`supabase/migrations/20260607170000_rls_policies.sql`](../supabase/migrations/20260607170000_rls_policies.sql) | **RLS 再適用・正本 migration**（A6、idempotent） |
| [`supabase/migrations/20260607150000_auth_user_profile_trigger.sql`](../supabase/migrations/20260607150000_auth_user_profile_trigger.sql) | **`auth.users` → `public.users` 自動作成トリガー**（A2） |
| [`supabase/migrations/20260607160000_messages_retention_cron.sql`](../supabase/migrations/20260607160000_messages_retention_cron.sql) | **`messages` 30日削除 cron**（A3） |
| [`supabase/migrations/20260608110000_user_daily_groq_usage.sql`](../supabase/migrations/20260608110000_user_daily_groq_usage.sql) | **Groq 日次トークン集計**（B7） |

仕様の根拠: `09-implementation-spec-detailed.md`。

## 適用の推奨順序

**リモート / ローカル Supabase（推奨）**

1. `supabase link --project-ref <ref>` のあと `supabase db push` で `20260603120000_plotty_schema.sql` を適用
2. Edge Functions ローカル開発時は `supabase/.env.example` を `supabase/.env.local` にコピーして Secrets を設定（`09` §10.2）
3. `supabase db push` で `20260607150000_auth_user_profile_trigger.sql` を適用（A2）
4. `supabase db push` で `20260607160000_messages_retention_cron.sql` を適用（A3。`pg_cron` 拡張を有効化してから）
5. `supabase db push` で `20260607170000_rls_policies.sql` を適用（A6。手動 SQL 環境のポリシー揃え・以降の RLS 正本）
6. `supabase db push` で `20260608100000_messages_client_message_id.sql` を適用（B5）
7. `supabase db push` で `20260608110000_user_daily_groq_usage.sql` を適用（B7）

**手動 SQL（参考）**

1. `plotty_schema.sql`（スキーマ本体）
2. 上記 2・3 と同順

## 対象テーブル

- `public.users` — `auth.users` と 1 対 1
- `public.messages` — 対話ログ（`related_entities` / `analysis_results_encrypted`、`expires_at` は `created_at + 720時間` を **BEFORE INSERT トリガー**で設定。※`timestamptz` の GENERATED 式は環境により `generation expression is not immutable` で失敗するため生成列にはしない）
- `public.schedules` / `public.tasks` / `public.memos` — 共通暗号列 + 種別ごとの列

## RLS（本 DDL に含む内容）

- 正本 SQL: **`edge/sql/rls-policies.sql`**。Supabase 適用: **A6 migration**
- `auth.uid() = user_id` の本人データのみ（`users` は `id = auth.uid()`）
- `messages` は **SELECT / INSERT のみ**（更新・削除はクライアント JWT では不可。バッチ・Edge の `service_role` で実施する想定）
- A1 migration にも初回 RLS あり。A6 は **DROP IF EXISTS + CREATE** で本番・開発を同一手順に揃える

## 注意事項

- 本 DDL は初回作成用。運用では **Supabase migration** などに移し、重複実行時の `CREATE POLICY` 衝突には `DROP POLICY IF EXISTS` の整備を推奨する。
- メッセージの物理削除ジョブは **必ず `service_role` 相当の権限**で動かす（RLS バイパスが必要なため）。

## 今後の migration（施工待ち）

`plotty_schema.sql` 適用**後**、別 migration で追加予定。設計詳細: `docs/contracts/implementation-notes.md` §3。

| 追加対象 | 用途 |
|---|---|
| （B5/B7 適用済み migration を参照） | — |
