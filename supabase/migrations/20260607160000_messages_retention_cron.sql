-- A3: messages 30日削除 cron（UTC 03:00 日次）
-- ソース正本: edge/sql/messages-retention-job.sql
-- 参照: docs/02-mvp-scope-and-ops.md, docs/07-rls-and-security-ops.md
--
-- 前提: Supabase Dashboard → Database → Extensions で pg_cron が有効であること。
-- 物理削除は service_role / cron 経路のみ（RLS バイパスが必要）。

create extension if not exists pg_cron with schema extensions;

-- 同名ジョブがあれば削除してから再登録（migration 再実行対策）
do $$
declare
  job_id bigint;
begin
  select j.jobid into job_id
  from cron.job j
  where j.jobname = 'delete-expired-messages-daily';

  if job_id is not null then
    perform cron.unschedule(job_id);
  end if;
end;
$$;

select cron.schedule(
  'delete-expired-messages-daily',
  '0 3 * * *',
  $$
  delete from public.messages
  where expires_at < (now() at time zone 'utc');
  $$
);
