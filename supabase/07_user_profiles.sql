-- =============================================================================
-- Tabela: user_profiles (perfil de usuário — avatar, capa, nome, bio, nível)
-- Storage: buckets avatars e covers para upload de imagens.
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Depois: Storage > New bucket > "avatars" e "covers" (public ou com RLS).
-- =============================================================================

create table if not exists public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text,
  bio text,
  avatar_url text,
  cover_url text,
  watch_hours numeric not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

comment on table public.user_profiles is 'Perfil do usuário (nome, bio, avatar, capa, horas assistidas)';
create unique index if not exists idx_user_profiles_user_id on public.user_profiles (user_id);

alter table public.user_profiles enable row level security;

-- Usuário autenticado pode ler qualquer perfil (para exibir em salas de cinema etc.)
drop policy if exists "Allow read user_profiles" on public.user_profiles;
create policy "Allow read user_profiles"
  on public.user_profiles for select using (true);

-- Usuário só pode inserir/atualizar o próprio perfil
drop policy if exists "Allow insert own user_profile" on public.user_profiles;
create policy "Allow insert own user_profile"
  on public.user_profiles for insert
  with check (auth.uid() = user_id);

drop policy if exists "Allow update own user_profile" on public.user_profiles;
create policy "Allow update own user_profile"
  on public.user_profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- STORAGE (obrigatório para avatar e capa):
-- 1. Dashboard > Storage > New bucket > Nome: "avatars" > Public: ON > Create.
-- 2. New bucket > Nome: "covers" > Public: ON > Create.
-- 3. Em cada bucket, Policies > New policy:
--    - avatars: INSERT com check (bucket_id = 'avatars' e (storage.foldername(name))[1] = auth.uid()::text)
--    - avatars: SELECT com check (bucket_id = 'avatars') para leitura pública.
--    - covers: mesmo padrão para "covers".
-- =============================================================================
