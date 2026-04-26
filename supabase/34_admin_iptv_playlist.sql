-- =============================================================================
-- Lista IPTV (Xtream) definida pelo admin para um cliente — guardada na nuvem
-- O app do cliente sincroniza e importa canais localmente (SQLite).
-- Execute após 02_admins.sql e 07_user_profiles.sql (user_id = auth.users).
-- =============================================================================

create table if not exists public.admin_iptv_playlist (
  user_id uuid primary key references auth.users(id) on delete cascade,
  playlist_name text not null default 'IPTV Principal',
  xtream_url text not null,
  notes text,
  updated_at timestamptz not null default now(),
  updated_by_email text
);

comment on table public.admin_iptv_playlist is 'URL Xtream (xtream://user:pass@host) definida pelo admin para o utilizador; o app importa ao abrir.';

create index if not exists idx_admin_iptv_updated on public.admin_iptv_playlist (updated_at desc);

alter table public.admin_iptv_playlist enable row level security;

-- Cliente lê só a própria linha
drop policy if exists "User read own admin_iptv_playlist" on public.admin_iptv_playlist;
create policy "User read own admin_iptv_playlist"
  on public.admin_iptv_playlist for select
  using (auth.uid() = user_id);

-- Admin: ler qualquer (para UI)
drop policy if exists "Admins read admin_iptv_playlist" on public.admin_iptv_playlist;
create policy "Admins read admin_iptv_playlist"
  on public.admin_iptv_playlist for select
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- Admin: inserir/atualizar/apagar
drop policy if exists "Admins manage admin_iptv_playlist" on public.admin_iptv_playlist;
create policy "Admins manage admin_iptv_playlist"
  on public.admin_iptv_playlist for all
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  with check (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );
