-- =============================================================================
-- Contagens de favoritos no perfil (canais + VOD) para exibir no perfil público.
-- Sincronizadas pelo app quando o usuário altera favoritos locais.
-- Execute no Supabase SQL Editor após 21_user_vod_watch_history.sql
-- =============================================================================

alter table public.user_profiles
  add column if not exists fav_channels_count integer not null default 0,
  add column if not exists fav_vod_count integer not null default 0;

comment on column public.user_profiles.fav_channels_count is 'Número de canais favoritos (sincronizado pelo app)';
comment on column public.user_profiles.fav_vod_count is 'Número de filmes/séries favoritos (sincronizado pelo app)';
