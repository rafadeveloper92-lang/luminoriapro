-- =============================================================================
-- Tabela: support_tickets (chamados de suporte — usuários para o admin)
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- =============================================================================

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  email text not null,
  subject text not null,
  message text not null,
  status text not null default 'open' check (status in ('open', 'in_progress', 'closed')),
  admin_reply text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

comment on table public.support_tickets is 'Chamados de suporte enviados pelos utilizadores (Luminoria)';
create index if not exists idx_support_tickets_created_at on public.support_tickets (created_at desc);
create index if not exists idx_support_tickets_status on public.support_tickets (status);

alter table public.support_tickets enable row level security;

-- Utilizador logado pode inserir o seu próprio ticket
drop policy if exists "Users can insert own ticket" on public.support_tickets;
create policy "Users can insert own ticket"
  on public.support_tickets for insert
  with check (auth.uid() = user_id or user_id is null);

-- Utilizador pode ver os seus tickets; admin pode ver todos
drop policy if exists "Users can read own tickets" on public.support_tickets;
create policy "Users can read own tickets"
  on public.support_tickets for select
  using (
    auth.uid() = user_id
    or exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- Apenas admin pode atualizar (fechar/responder)
drop policy if exists "Allow all update for support" on public.support_tickets;
create policy "Admin can update tickets"
  on public.support_tickets for update
  using (exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email')))
  with check (true);
