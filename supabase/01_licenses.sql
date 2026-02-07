-- =============================================================================
-- Tabela: licenses (assinaturas por usuário — id único por conta)
-- Licença vinculada ao user_id (auth.users) para maior segurança.
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- =============================================================================

-- Tabela de licenças (um registro por usuário — user_id único)
create table if not exists public.licenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  device_id text,
  expires_at timestamptz not null,
  plan text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Comentários
comment on table public.licenses is 'Licenças/assinaturas por usuário (Luminoria)';
comment on column public.licenses.user_id is 'ID único do usuário (auth.users.id) — uma licença por conta';
comment on column public.licenses.device_id is 'Opcional: ID do dispositivo (ex: lotus_abc123...)';
comment on column public.licenses.expires_at is 'Data/hora UTC de expiração; se passou, acesso bloqueado';
comment on column public.licenses.plan is 'Ex: 30d, 1y (informativo)';
comment on column public.licenses.notes is 'Ex: Cliente João - Plano Anual';

-- Índices
create index if not exists idx_licenses_user_id on public.licenses (user_id);
create index if not exists idx_licenses_device_id on public.licenses (device_id) where device_id is not null;
create index if not exists idx_licenses_expires_at on public.licenses (expires_at desc);

-- Row Level Security (RLS)
alter table public.licenses enable row level security;

-- Policy: leitura para app (verificação de licença por user_id)
drop policy if exists "Allow public read for license check" on public.licenses;
create policy "Allow public read for license check"
  on public.licenses for select
  using (true);

-- Policy: atualização (painel admin edita assinaturas)
drop policy if exists "Allow public update for admin" on public.licenses;
create policy "Allow public update for admin"
  on public.licenses for update
  using (true)
  with check (true);

-- Policy: insert (admin ou sistema ao criar licença para um user_id)
drop policy if exists "Allow public insert for admin" on public.licenses;
create policy "Allow public insert for admin"
  on public.licenses for insert
  with check (true);
