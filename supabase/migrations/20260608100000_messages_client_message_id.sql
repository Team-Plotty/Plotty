-- B5: client_message_id 冪等キー
-- 正本: docs/contracts/api-contract-mvp.md §5

set search_path = public;

alter table public.messages add column if not exists client_message_id text;

comment on column public.messages.client_message_id is 'チャット POST 冪等キー（user ロールのみ）';

create unique index if not exists messages_user_client_message_id_uidx
  on public.messages (user_id, client_message_id)
  where client_message_id is not null and role = 'user';
