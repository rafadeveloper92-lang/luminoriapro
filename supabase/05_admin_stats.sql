-- =============================================================================
-- Estatísticas do painel admin: total de contas, utilizadores online,
-- e tabela para eventos de pagamento (Stripe).
-- Execute após 02_admins, 04_support_tickets. Ordem: 05_admin_stats.
-- =============================================================================

-- Função: total de contas (auth.users) — só admins
create or replace function public.get_user_count()
returns bigint
language sql
security definer
set search_path = public
as $$
  select count(*)::bigint from auth.users
  where exists (
    select 1 from public.admins a
    where a.email = (auth.jwt() ->> 'email')
  );
$$;

comment on function public.get_user_count() is 'Total de utilizadores registados; apenas admins podem chamar';

grant execute on function public.get_user_count() to authenticated;
grant execute on function public.get_user_count() to anon;


-- Tabela: presença (last_seen) para "utilizadores online"
create table if not exists public.user_activity (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_seen timestamptz not null default now()
);

comment on table public.user_activity is 'Última atividade do utilizador; usado para contar "online agora" (last_seen nos últimos 5 min)';

alter table public.user_activity enable row level security;

-- Utilizador pode inserir/atualizar apenas a sua linha
drop policy if exists "User can upsert own activity" on public.user_activity;
create policy "User can upsert own activity"
  on public.user_activity for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Admins podem ler tudo (para contar online)
drop policy if exists "Admins can read activity" on public.user_activity;
create policy "Admins can read activity"
  on public.user_activity for select
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );


-- Função: contagem de utilizadores "online" (last_seen nos últimos 5 minutos)
create or replace function public.get_online_count()
returns bigint
language sql
security definer
set search_path = public
as $$
  select count(*)::bigint from public.user_activity
  where last_seen > (now() - interval '5 minutes')
  and exists (
    select 1 from public.admins a
    where a.email = (auth.jwt() ->> 'email')
  );
$$;

comment on function public.get_online_count() is 'Número de utilizadores com last_seen nos últimos 5 min; apenas admins';

grant execute on function public.get_online_count() to authenticated;
grant execute on function public.get_online_count() to anon;


-- Tabela: eventos de pagamento Stripe (falhas e sucessos)
create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  stripe_event_id text unique,
  type text not null,
  customer_email text,
  amount_cents bigint,
  currency text,
  failure_reason text,
  created_at timestamptz default now()
);

comment on table public.payment_events is 'Eventos Stripe (invoice.payment_failed, invoice.paid) para histórico no painel admin';

create index if not exists idx_payment_events_created_at on public.payment_events (created_at desc);
create index if not exists idx_payment_events_type on public.payment_events (type);

alter table public.payment_events enable row level security;

-- Apenas admins podem ler
drop policy if exists "Admins can read payment_events" on public.payment_events;
create policy "Admins can read payment_events"
  on public.payment_events for select
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- Inserção: apenas via service role no webhook (sem policy = apenas backend insere)
