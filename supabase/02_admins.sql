-- =============================================================================
-- Tabela: admins (emails que veem o botão "Painel Administrativo" nas Configurações)
-- O app usa Supabase Auth: o usuário faz login com email/senha; se o email
-- estiver nesta tabela, o botão do painel aparece.
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- =============================================================================

-- Tabela de administradores (apenas o email)
create table if not exists public.admins (
  email text primary key,
  created_at timestamptz default now()
);

comment on table public.admins is 'Emails que têm acesso ao Painel Administrativo (Luminoria)';

-- Row Level Security (RLS)
alter table public.admins enable row level security;

-- Policy: o usuário logado só pode verificar se o PRÓPRIO email está na lista
-- (evita que qualquer um leia a lista inteira de admins)
drop policy if exists "User can check own email" on public.admins;
create policy "User can check own email"
  on public.admins for select
  using (auth.jwt() ->> 'email' = email);
