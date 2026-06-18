-- Plotty MVP スキーマ（PostgreSQL / Supabase 想定）
-- 要件正本: docs/09-implementation-spec-detailed.md
-- Supabase 適用: supabase/migrations/20260603120000_plotty_schema.sql（A1）
--
-- 前提:
-- - auth.users は Supabase Auth が管理する
-- - public.users は auth.users と id で 1 対 1（トリガーで作成する想定。本 DDL には含めない）

-- ── 共通: UUID 生成（Supabase で通常有効）
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";

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

-- ── メッセージ（30日で物理削除。expires は created + 720h／生成列にはしない）
-- メモ: timestamptz + interval の GENERATED は PG が「immutable でない」と拒否することがあるため、BEFORE INSERT トリガーで設定する。
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content_encrypted text not null,
  iv text not null,
  related_entities jsonb not null default '[]'::jsonb,
  analysis_results_encrypted jsonb,
  client_message_id text,
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null
);

comment on table public.messages is '対話ログ（暗号化済み）。30日経過で cron により物理削除';
comment on column public.messages.related_entities is '例: [{"type":"schedule","id":"uuid"},...]';
comment on column public.messages.analysis_results_encrypted is '例: {"iv":"...","data":"..."}（暗号化済みペイロード）';
comment on column public.messages.expires_at is 'created_at + 720時間。INSERT 前トリガーで自動設定';
comment on column public.messages.client_message_id is 'チャット POST 冪等キー（user ロールのみ。B5 migration）';

create unique index if not exists messages_user_client_message_id_uidx
  on public.messages (user_id, client_message_id)
  where client_message_id is not null and role = 'user';

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

-- ── messages: expires_at = created_at + 720時間（immutable 要件を回避するためトリガーで設定）
create or replace function public.set_messages_expires_at()
returns trigger
language plpgsql
as $$
begin
  new.expires_at := new.created_at + interval '720 hours';
  return new;
end;
$$;

create trigger messages_set_expires_at
  before insert on public.messages
  for each row execute procedure public.set_messages_expires_at();

-- ── updated_at 自動更新トリガー用関数（汎用）
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

create trigger schedules_set_updated_at
  before update on public.schedules
  for each row execute procedure public.set_updated_at();

create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute procedure public.set_updated_at();

create trigger memos_set_updated_at
  before update on public.memos
  for each row execute procedure public.set_updated_at();

-- ── Row Level Security
-- 正本: edge/sql/rls-policies.sql
-- Supabase 適用: supabase/migrations/20260607170000_rls_policies.sql（A6）
-- A1 migration にも初回適用用コピーあり。以降の RLS 変更は rls-policies.sql → A6 系 migration で行う。

-- メモ: public.users は RLS で INSERT が無い。Supabase の慣例では auth.users に対する SECURITY DEFINER のトリガーで挿入する。
-- 適用済み migration: supabase/migrations/20260607150000_auth_user_profile_trigger.sql（A2）
