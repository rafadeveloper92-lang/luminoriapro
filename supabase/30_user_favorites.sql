-- =============================================================================
-- Favoritos por usuário no Supabase (canais + filmes + séries)
--
-- Antes, o app salvava favoritos nas tabelas locais SQLite `favorites` e
-- `vod_favorites`, sincronizando apenas contagens em user_profiles. Para um app
-- social/multi-dispositivo, os itens favoritos precisam estar vinculados ao
-- usuário autenticado no Supabase.
-- =============================================================================

create table if not exists public.user_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  favorite_type text not null check (favorite_type in ('channel', 'movie', 'series')),
  item_key text not null,
  playlist_key text,
  playlist_name text,
  metadata jsonb not null default '{}'::jsonb,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.user_favorites is 'Favoritos do usuário: canais, filmes e séries salvos no Supabase';
comment on column public.user_favorites.item_key is 'Chave estável do favorito. Para canais: channel:<url>; para VOD: movie:<stream_id> ou series:<stream_id>.';
comment on column public.user_favorites.playlist_key is 'Chave estável opcional da lista de origem, independente do ID local.';
comment on column public.user_favorites.metadata is 'Metadados necessários para reconstruir o card sem depender do banco local.';

create unique index if not exists idx_user_favorites_unique
  on public.user_favorites (user_id, item_key);

create index if not exists idx_user_favorites_user_position
  on public.user_favorites (user_id, favorite_type, position, created_at desc);

alter table public.user_favorites enable row level security;

drop policy if exists "Allow read own user_favorites" on public.user_favorites;
create policy "Allow read own user_favorites"
  on public.user_favorites for select
  using (auth.uid() = user_id);

drop policy if exists "Allow insert own user_favorites" on public.user_favorites;
create policy "Allow insert own user_favorites"
  on public.user_favorites for insert
  with check (auth.uid() = user_id);

drop policy if exists "Allow update own user_favorites" on public.user_favorites;
create policy "Allow update own user_favorites"
  on public.user_favorites for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Allow delete own user_favorites" on public.user_favorites;
create policy "Allow delete own user_favorites"
  on public.user_favorites for delete
  using (auth.uid() = user_id);
