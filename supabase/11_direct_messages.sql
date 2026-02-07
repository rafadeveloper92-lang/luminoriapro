-- =============================================================================
-- Chat direto entre amigos (Supabase)
-- Execute no SQL Editor após 10_friends.sql
-- =============================================================================

create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references auth.users(id) on delete cascade,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  text text not null,
  read_at timestamptz,
  created_at timestamptz default now()
);

comment on table public.direct_messages is 'Mensagens diretas entre usuários (chat)';
create index if not exists idx_dm_from_to on public.direct_messages(from_user_id, to_user_id);
create index if not exists idx_dm_to_created on public.direct_messages(to_user_id, created_at desc);
alter table public.direct_messages enable row level security;

drop policy if exists "Allow read own messages" on public.direct_messages;
create policy "Allow read own messages"
  on public.direct_messages for select
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

drop policy if exists "Allow insert own message" on public.direct_messages;
create policy "Allow insert own message"
  on public.direct_messages for insert
  with check (auth.uid() = from_user_id);

drop policy if exists "Allow update read_at received" on public.direct_messages;
create policy "Allow update read_at received"
  on public.direct_messages for update
  using (auth.uid() = to_user_id)
  with check (auth.uid() = to_user_id);
