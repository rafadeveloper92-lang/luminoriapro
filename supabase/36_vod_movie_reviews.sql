-- =============================================================================
-- Comentários e avaliações (1–5 estrelas) por filme VOD (stream_id da lista Xtream).
-- Execute no Supabase SQL Editor após 07_user_profiles.sql (user_id alinhado com auth).
-- =============================================================================

create table if not exists public.vod_movie_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  stream_id text not null,
  movie_name text,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, stream_id)
);

create index if not exists idx_vod_movie_reviews_stream on public.vod_movie_reviews (stream_id);

comment on table public.vod_movie_reviews is 'Avaliações e comentários de utilizadores por filme (identificado por stream_id VOD)';

alter table public.vod_movie_reviews enable row level security;

drop policy if exists "vod_movie_reviews_select_all" on public.vod_movie_reviews;
create policy "vod_movie_reviews_select_all"
  on public.vod_movie_reviews for select
  using (true);

drop policy if exists "vod_movie_reviews_insert_own" on public.vod_movie_reviews;
create policy "vod_movie_reviews_insert_own"
  on public.vod_movie_reviews for insert
  with check (auth.uid() = user_id);

drop policy if exists "vod_movie_reviews_update_own" on public.vod_movie_reviews;
create policy "vod_movie_reviews_update_own"
  on public.vod_movie_reviews for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "vod_movie_reviews_delete_own" on public.vod_movie_reviews;
create policy "vod_movie_reviews_delete_own"
  on public.vod_movie_reviews for delete
  using (auth.uid() = user_id);

-- Realtime opcional (comentários novos em tempo real no detalhe do filme)
do $$
begin
  alter publication supabase_realtime add table public.vod_movie_reviews;
exception
  when duplicate_object then null;
end $$;
