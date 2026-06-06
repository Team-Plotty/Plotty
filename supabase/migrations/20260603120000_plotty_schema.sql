-- A1: Plotty MVP スキーマ（Supabase migration）
-- ソース正本: edge/sql/plotty_schema.sql
-- 要件: docs/09-implementation-spec-detailed.md, docs/13-database-ddl.md
--
-- 含まないもの（別 migration）:
-- - auth.users → public.users トリガー（A2）
-- - messages 30日削除 cron（A3）
-- - client_message_id / user_daily_groq_usage（Phase B migration）

set search_path = public;

-- ── アプリ側ユーザープロファイル
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  timezone text not null default 'Asia/Tokyo',
  default_category text not null default 'memo',
  ai_persona_config jsonb not null default '{}'::jsonb,
  encryption_key_id text,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.users is '認証ユーザーに紐づくプロファイル・AI設定（auth.users と 1対1）';
comment on column public.users.encryption_key_id is 'Vault 上のユーザー鍵参照。初回 null 許容';

-- ── メッセージ（30日で物理削除。expires は created + 720h／BEFORE INSERT トリガーで設定）
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content_encrypted text not null,
  iv text not null,
  related_entities jsonb not null default '[]'::jsonb,
  analysis_results_encrypted jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null
);

comment on table public.messages is '対話ログ（暗号化済み）。30日経過で cron により物理削除';
comment on column public.messages.related_entities is '例: [{"type":"schedule","id":"uuid"},...]';
comment on column public.messages.analysis_results_encrypted is '例: {"iv":"...","data":"..."}（暗号化済みペイロード）';
comment on column public.messages.expires_at is 'created_at + 720時間。INSERT 前トリガーで自動設定';

create index if not exists messages_user_created_idx
  on public.messages (user_id, created_at desc);

-- ── 実体共通カラムを持つ3テーブル
create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  source_message_id uuid references public.messages (id) on delete set null,
  origin_text_encrypted text,
  title_encrypted text not null,
  title_hash text not null,
  iv text not null,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  start_at timestamptz not null,
  end_at timestamptz,
  is_all_day boolean not null default false,
  location text
);

comment on table public.schedules is 'カレンダー予定（暗号フィールドあり）';

create index if not exists schedules_user_start_idx
  on public.schedules (user_id, start_at asc) where not is_deleted;

create index if not exists schedules_title_hash_idx
  on public.schedules (user_id, title_hash) where not is_deleted;

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  source_message_id uuid references public.messages (id) on delete set null,
  origin_text_encrypted text,
  title_encrypted text not null,
  title_hash text not null,
  iv text not null,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  is_completed boolean not null default false,
  due_date timestamptz not null,
  priority smallint not null default 2 check (priority between 1 and 3)
);

comment on table public.tasks is 'タスク';

create index if not exists tasks_user_due_idx
  on public.tasks (user_id, due_date asc) where not is_deleted;

create index if not exists tasks_title_hash_idx
  on public.tasks (user_id, title_hash) where not is_deleted;

create table if not exists public.memos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  source_message_id uuid references public.messages (id) on delete set null,
  origin_text_encrypted text,
  title_encrypted text not null,
  title_hash text not null,
  iv text not null,
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  content_encrypted text not null,
  is_pinned boolean not null default false
);

comment on table public.memos is '長期ストックメモ';

create index if not exists memos_user_updated_idx
  on public.memos (user_id, updated_at desc) where not is_deleted;

create index if not exists memos_title_hash_idx
  on public.memos (user_id, title_hash) where not is_deleted;

-- ── messages: expires_at = created_at + 720時間
create or replace function public.set_messages_expires_at()
returns trigger
language plpgsql
as $$
begin
  new.expires_at := new.created_at + interval '720 hours';
  return new;
end;
$$;

drop trigger if exists messages_set_expires_at on public.messages;
create trigger messages_set_expires_at
  before insert on public.messages
  for each row execute procedure public.set_messages_expires_at();

-- ── updated_at 自動更新
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists schedules_set_updated_at on public.schedules;
create trigger schedules_set_updated_at
  before update on public.schedules
  for each row execute procedure public.set_updated_at();

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute procedure public.set_updated_at();

drop trigger if exists memos_set_updated_at on public.memos;
create trigger memos_set_updated_at
  before update on public.memos
  for each row execute procedure public.set_updated_at();

-- ── Row Level Security（方針: 本人のみ。messages の UPDATE/DELETE はクライアント JWT では不可）
alter table public.users enable row level security;
alter table public.messages enable row level security;
alter table public.schedules enable row level security;
alter table public.tasks enable row level security;
alter table public.memos enable row level security;

-- public.users
drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
  for select using (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own" on public.users
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- messages（クライアントは閲覧・挿入のみ想定。更新・削除は service_role / cron）
drop policy if exists "messages_select_own" on public.messages;
create policy "messages_select_own" on public.messages
  for select using (auth.uid() = user_id);

drop policy if exists "messages_insert_own" on public.messages;
create policy "messages_insert_own" on public.messages
  for insert with check (auth.uid() = user_id);

-- schedules / tasks / memos
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
