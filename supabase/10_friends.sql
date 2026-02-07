-- =============================================================================
-- Sistema de Amigos Luminora (Supabase - dados na nuvem)
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Usuário troca de celular = dados preservados na nuvem.
-- =============================================================================

-- Tabela: user_status (status e conteúdo assistindo por usuário)
create table if not exists public.user_status (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'online' check (status in ('online', 'busy', 'invisible')),
  playing_content text,
  updated_at timestamptz default now()
);

comment on table public.user_status is 'Status do usuário (online/ocupado/invisível) e filme/série assistindo';
alter table public.user_status enable row level security;

drop policy if exists "Allow read user_status" on public.user_status;
create policy "Allow read user_status"
  on public.user_status for select using (true);

drop policy if exists "Allow insert own user_status" on public.user_status;
create policy "Allow insert own user_status"
  on public.user_status for insert
  with check (auth.uid() = user_id);

drop policy if exists "Allow update own user_status" on public.user_status;
create policy "Allow update own user_status"
  on public.user_status for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Tabela: friends (relação de amizade - user_id é eu, friend_user_id é o amigo)
create table if not exists public.friends (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_user_id uuid not null references auth.users(id) on delete cascade,
  is_favorite boolean not null default false,
  position int not null default 0,
  created_at timestamptz default now(),
  unique(user_id, friend_user_id)
);

comment on table public.friends is 'Amigos do usuário (dados na nuvem)';
create index if not exists idx_friends_user_id on public.friends(user_id);
create index if not exists idx_friends_favorite on public.friends(user_id, is_favorite);
alter table public.friends enable row level security;

drop policy if exists "Allow CRUD own friends" on public.friends;
create policy "Allow CRUD own friends"
  on public.friends for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Tabela: friend_requests (pedidos pendentes - from envia para to)
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references auth.users(id) on delete cascade,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique(from_user_id, to_user_id)
);

comment on table public.friend_requests is 'Pedidos de amizade pendentes';
create index if not exists idx_friend_requests_to on public.friend_requests(to_user_id);
alter table public.friend_requests enable row level security;

drop policy if exists "Allow read own friend_requests" on public.friend_requests;
create policy "Allow read own friend_requests"
  on public.friend_requests for select
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

drop policy if exists "Allow insert friend_request" on public.friend_requests;
create policy "Allow insert friend_request"
  on public.friend_requests for insert
  with check (auth.uid() = from_user_id);

drop policy if exists "Allow delete received friend_request" on public.friend_requests;
create policy "Allow delete received friend_request"
  on public.friend_requests for delete
  using (auth.uid() = to_user_id or auth.uid() = from_user_id);
