# 03. データモデルと暗号化

## テーブル概要

- `messages`: 対話ログ（30日で削除）
- `schedules` / `tasks` / `memos`: ユーザー資産として保持
- `public.users`: `auth.users` と1対1で拡張情報を保持

## `messages` の確定事項

- 生成先参照は `related_entities`（jsonb）に統一
  - 形式: `[{"type":"schedule","id":"uuid"},{"type":"task","id":"uuid"}]`
- AI解析結果は `analysis_results_encrypted`（jsonb）に保存
  - 形式: `{"iv":"...","data":"..."}`

## 暗号化範囲

- MVPで暗号化対象とする主フィールド:
  - `title`
  - `content`
  - `origin_text`
- 検索用は `title_hash`（HMAC-SHA256 + ペッパー）

## 鍵管理

- 復号鍵はクライアントに持たせない
- Vaultで管理し、**Supabase Edge Functions**（`plotty-api`）で参照（MVP は Functions Secrets）
- `public.users.encryption_key_id` は初回アクション時に設定可
