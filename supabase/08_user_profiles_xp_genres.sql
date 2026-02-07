-- =============================================================================
-- Novos campos em user_profiles: XP, gêneros favoritos, estado civil, país, cidade
-- Execute no Supabase SQL Editor após 07_user_profiles.sql
-- =============================================================================

alter table public.user_profiles
  add column if not exists xp integer not null default 0,
  add column if not exists favorite_genres text[] default '{}',
  add column if not exists marital_status text,
  add column if not exists country_code text,
  add column if not exists city text;

comment on column public.user_profiles.xp is 'Pontos de experiência (ganhos ao assistir)';
comment on column public.user_profiles.favorite_genres is 'Até 4 gêneros favoritos (ex: TERROR, AÇÃO)';
comment on column public.user_profiles.marital_status is 'Estado civil';
comment on column public.user_profiles.country_code is 'Código ISO do país (ex: BR, PT)';
comment on column public.user_profiles.city is 'Cidade';
