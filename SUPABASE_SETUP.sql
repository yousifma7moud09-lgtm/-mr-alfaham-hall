-- على الفحم: إعداد قاعدة بيانات المزامنة السحابية
-- شغّل هذا الملف مرة واحدة في Supabase Dashboard > SQL Editor.
-- لا تستخدم service_role/secret key في المتصفح.
create table if not exists public.hall_state (
  id integer primary key check (id = 1),
  data jsonb not null default '{"employees":[],"logs":[]}'::jsonb,
  settings jsonb not null default '{"breakMinutes":60,"breakLimit":10,"penaltyRate":2}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.hall_state enable row level security;
revoke all on public.hall_state from anon;
grant select, insert, update, delete on public.hall_state to authenticated;

drop policy if exists "trusted users can read hall state" on public.hall_state;
drop policy if exists "trusted users can insert hall state" on public.hall_state;
drop policy if exists "trusted users can update hall state" on public.hall_state;
create policy "trusted users can read hall state"
  on public.hall_state for select to authenticated using (true);
create policy "trusted users can insert hall state"
  on public.hall_state for insert to authenticated with check (id = 1);
create policy "trusted users can update hall state"
  on public.hall_state for update to authenticated using (true) with check (id = 1);

-- أضف الجدول إلى Realtime إذا لم يكن موجودًا بالفعل.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'hall_state'
  ) then
    alter publication supabase_realtime add table public.hall_state;
  end if;
end $$;
