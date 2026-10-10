-- タスク締切の「時刻指定あり / 日付のみ」を区別する
-- 正本: edge/sql/plotty_schema.sql
-- 既存行は時刻を指定する UI が無い時期に作られたため、日付のみ（false）として扱う

set search_path = public;

alter table public.tasks add column if not exists due_has_time boolean not null default false;

comment on column public.tasks.due_has_time is '締切に時刻まで指定したか。false は日付のみ（due_date の時刻は当日末で表示しない）';
