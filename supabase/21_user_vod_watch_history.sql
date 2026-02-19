-- =============================================================================
-- Timeline de perfil no Supabase: filmes/séries assistidos por usuário.
-- Permite que ao visitar perfil de amigo se veja a linha do tempo dele.
-- Execute no Supabase SQL Editor após 08_user_profiles_xp_genres.sql
-- =============================================================================

create table if not exists public.user_vod_watch_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  stream_id text not null,
  name text not null,
  poster_url text,
  content_type text not null default 'movie',
  watched_at timestamptz not null default now(),
  created_at timestamptz default now()
);

comment on table public.user_vod_watch_history is 'Timeline do perfil: últimos filmes/séries assistidos por usuário (visível para amigos)';
create index if not exists idx_user_vod_watch_history_user_id on public.user_vod_watch_history (user_id);
create index if not exists idx_user_vod_watch_history_watched_at on public.user_vod_watch_history (user_id, watched_at desc);

-- Manter no máximo um registro por (user_id, stream_id): o mais recente
create unique index if not exists idx_user_vod_watch_history_user_stream
  on public.user_vod_watch_history (user_id, stream_id);

alter table public.user_vod_watch_history enable row level security;

-- Usuário autenticado pode inserir/atualizar/apagar só os próprios registros
drop policy if exists "Allow insert own vod history" on public.user_vod_watch_history;
create policy "Allow insert own vod history"
  on public.user_vod_watch_history for insert
  with check (auth.uid() = user_id);

drop policy if exists "Allow update own vod history" on public.user_vod_watch_history;
create policy "Allow update own vod history"
  on public.user_vod_watch_history for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Allow delete own vod history" on public.user_vod_watch_history;
create policy "Allow delete own vod history"
  on public.user_vod_watch_history for delete
  using (auth.uid() = user_id);

-- Qualquer usuário autenticado pode ler (para ver timeline de amigos)
drop policy if exists "Allow read vod history" on public.user_vod_watch_history;
create policy "Allow read vod history"
  on public.user_vod_watch_history for select
  using (true);
