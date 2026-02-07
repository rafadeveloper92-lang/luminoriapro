-- =============================================================================
-- Tabela: cinema_rooms (Salas de Cinema — sincronização de playback)
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Para Realtime: Dashboard > Database > Replication > adicione cinema_rooms.
-- =============================================================================

create table if not exists public.cinema_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_user_id text,
  video_url text not null,
  video_name text not null,
  video_logo text,
  current_time_ms bigint not null default 0,
  is_playing boolean not null default false,
  created_at timestamptz default now()
);

comment on table public.cinema_rooms is 'Salas de cinema para assistir em grupo (sync play/pause/seek)';
create unique index if not exists idx_cinema_rooms_code on public.cinema_rooms (code);
create index if not exists idx_cinema_rooms_created_at on public.cinema_rooms (created_at desc);

alter table public.cinema_rooms enable row level security;

-- Qualquer um pode criar sala (anon ou autenticado)
drop policy if exists "Allow insert cinema_rooms" on public.cinema_rooms;
create policy "Allow insert cinema_rooms"
  on public.cinema_rooms for insert with check (true);

-- Qualquer um pode ler (para entrar por código e ver estado)
drop policy if exists "Allow select cinema_rooms" on public.cinema_rooms;
create policy "Allow select cinema_rooms"
  on public.cinema_rooms for select using (true);

-- Host pode atualizar (sync); em alternativa permitir update para todos
drop policy if exists "Allow update cinema_rooms" on public.cinema_rooms;
create policy "Allow update cinema_rooms"
  on public.cinema_rooms for update using (true);

-- Host pode deletar a sala
drop policy if exists "Allow delete cinema_rooms" on public.cinema_rooms;
create policy "Allow delete cinema_rooms"
  on public.cinema_rooms for delete using (true);

-- Ativar Realtime na tabela (Dashboard > Database > Replication > add cinema_rooms)
-- Ou execute: ALTER PUBLICATION supabase_realtime ADD TABLE public.cinema_rooms;
