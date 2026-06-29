-- A6: Row Level Security ポリシー（idempotent）
-- ソース正本: edge/sql/rls-policies.sql
-- 参照: docs/07-rls-and-security-ops.md
--
-- A1 migration ですでに同等ポリシーがある環境でも DROP IF EXISTS + CREATE で再適用可能。
-- 以降の RLS 変更は本 migration 系（rls-policies.sql）で管理する。

set search_path = public;

alter table public.users enable row level security;
alter table public.messages enable row level security;
alter table public.schedules enable row level security;
alter table public.tasks enable row level security;
alter table public.memos enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
  for select using (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own" on public.users
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "users_delete_own" on public.users;
create policy "users_delete_own" on public.users
  for delete using (auth.uid() = id);

drop policy if exists "messages_select_own" on public.messages;
create policy "messages_select_own" on public.messages
  for select using (auth.uid() = user_id);

drop policy if exists "messages_insert_own" on public.messages;
create policy "messages_insert_own" on public.messages
  for insert with check (auth.uid() = user_id);

drop policy if exists "schedules_select_own" on public.schedules;
create policy "schedules_select_own" on public.schedules
  for select using (auth.uid() = user_id);

drop policy if exists "schedules_insert_own" on public.schedules;
create policy "schedules_insert_own" on public.schedules
  for insert with check (auth.uid() = user_id);

drop policy if exists "schedules_update_own" on public.schedules;
create policy "schedules_update_own" on public.schedules
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "tasks_select_own" on public.tasks;
create policy "tasks_select_own" on public.tasks
  for select using (auth.uid() = user_id);

drop policy if exists "tasks_insert_own" on public.tasks;
create policy "tasks_insert_own" on public.tasks
  for insert with check (auth.uid() = user_id);

drop policy if exists "tasks_update_own" on public.tasks;
create policy "tasks_update_own" on public.tasks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "memos_select_own" on public.memos;
create policy "memos_select_own" on public.memos
  for select using (auth.uid() = user_id);

drop policy if exists "memos_insert_own" on public.memos;
create policy "memos_insert_own" on public.memos
  for insert with check (auth.uid() = user_id);

drop policy if exists "memos_update_own" on public.memos;
create policy "memos_update_own" on public.memos
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
