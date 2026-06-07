-- messages テーブルの30日削除ジョブ（UTC基準）
-- Supabase migration: supabase/migrations/20260607160000_messages_retention_cron.sql（A3）
select cron.schedule(
  'delete-expired-messages-daily',
  '0 3 * * *',
  $$
  delete from public.messages
  where created_at < (now() at time zone 'utc') - interval '720 hours';
  $$
);
