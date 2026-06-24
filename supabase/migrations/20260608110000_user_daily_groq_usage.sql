-- B7: Groq 日次トークン集計
-- 正本: docs/05-ai-groq-and-prompt-policy.md §利用量制限

set search_path = public;

create table if not exists public.user_daily_groq_usage (
  user_id uuid not null references public.users (id) on delete cascade,
  usage_date date not null,
  tokens_used bigint not null default 0,
  primary key (user_id, usage_date)
);

comment on table public.user_daily_groq_usage is 'Groq 日次トークン使用量（UTC 日付）';
