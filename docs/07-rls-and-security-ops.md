# 07. RLSとセキュリティ運用

## RLS基本ルール

- 原則: `user_id = auth.uid()`
- 対象: `messages`, `schedules`, `tasks`, `memos`, `public.users`
- 直接アクセス可能でも他人データは参照不可にする

## `service_role` 制約

使用を許可するのは以下のみ:

1. `pg_cron` による30日削除バッチ
2. **Supabase Edge Functions**（`plotty-api`）での鍵取得・復号処理
3. 管理ジョブ（明示的運用時）

禁止:

- クライアント到達可能経路での `service_role` 利用

## 運用ログ

- Supabase Edge Functions のログで `request_id`, `user_id`, `function_name`, `latency_ms`, `error_code` を記録
- 障害時に追跡可能な最小監査情報を残す
