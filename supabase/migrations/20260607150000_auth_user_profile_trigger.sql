-- A2: auth.users 作成時に public.users プロファイルを自動作成
-- 参照: docs/04-auth-and-account-linking.md, edge/sql/plotty_schema.sql 末尾テンプレ

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

-- トリガー適用前に既存 auth ユーザーを backfill
insert into public.users (id)
select id
from auth.users
on conflict (id) do nothing;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
