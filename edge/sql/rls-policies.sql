-- Plotty MVP Row Level Security（PostgreSQL / Supabase 想定）
-- 要件正本: docs/07-rls-and-security-ops.md, docs/10-api-rls-design-detailed.md
-- Supabase 適用: supabase/migrations/20260607170000_rls_policies.sql（A6）
--
-- 方針: 本人のみ（auth.uid() = user_id / users.id = auth.uid()）
-- messages: クライアント JWT は SELECT / INSERT のみ（UPDATE/DELETE は Edge service_role / cron）

set search_path = public;

alter table public.users enable row level security;
alter table public.messages enable row level security;
alter table public.schedules enable row level security;
alter table public.tasks enable row level security;
alter table public.memos enable row level security;

-- public.users（INSERT は auth トリガー security definer 経由。A2）
drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
  for select using (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own" on public.users
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "users_delete_own" on public.users;
create policy "users_delete_own" on public.users
  for delete using (auth.uid() = id);

-- messages
drop policy if exists "messages_select_own" on public.messages;
create policy "messages_select_own" on public.messages
  for select using (auth.uid() = user_id);

drop policy if exists "messages_insert_own" on public.messages;
create policy "messages_insert_own" on public.messages
  for insert with check (auth.uid() = user_id);

-- schedules
drop policy if exists "schedules_select_own" on public.schedules;
create policy "schedules_select_own" on public.schedules
  for select using (auth.uid() = user_id);

drop policy if exists "schedules_insert_own" on public.schedules;
create policy "schedules_insert_own" on public.schedules
  for insert with check (auth.uid() = user_id);

drop policy if exists "schedules_update_own" on public.schedules;
create policy "schedules_update_own" on public.schedules
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- tasks
drop policy if exists "tasks_select_own" on public.tasks;
create policy "tasks_select_own" on public.tasks
  for select using (auth.uid() = user_id);

drop policy if exists "tasks_insert_own" on public.tasks;
create policy "tasks_insert_own" on public.tasks
  for insert with check (auth.uid() = user_id);

drop policy if exists "tasks_update_own" on public.tasks;
create policy "tasks_update_own" on public.tasks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- memos
drop policy if exists "memos_select_own" on public.memos;
create policy "memos_select_own" on public.memos
  for select using (auth.uid() = user_id);

drop policy if exists "memos_insert_own" on public.memos;
create policy "memos_insert_own" on public.memos
  for insert with check (auth.uid() = user_id);

drop policy if exists "memos_update_own" on public.memos;
create policy "memos_update_own" on public.memos
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
