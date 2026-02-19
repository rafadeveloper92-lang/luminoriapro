-- =============================================================================
-- Ranking global mensal: tempo assistido por mês (minutos) e funções RPC
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- O ranking usa apenas o mês atual; todo mês "reseta" automaticamente.
--
-- OBRIGATÓRIO: Sem esta migração, o ranking global fica vazio mesmo com contas
-- criadas e tempo assistido (o app chama add_monthly_watch_minutes e get_global_ranking).
-- =============================================================================

-- Tabela: tempo assistido por usuário por mês
create table if not exists public.monthly_watch_time (
  user_id uuid not null references auth.users(id) on delete cascade,
  year_month text not null,
  watch_minutes integer not null default 0,
  primary key (user_id, year_month)
);

comment on table public.monthly_watch_time is 'Minutos assistidos por usuário por mês (ranking global mensal)';
create index if not exists idx_monthly_watch_time_year_month on public.monthly_watch_time(year_month);

alter table public.monthly_watch_time enable row level security;

-- Qualquer um pode ler (para exibir o ranking)
drop policy if exists "Allow read monthly_watch_time" on public.monthly_watch_time;
create policy "Allow read monthly_watch_time"
  on public.monthly_watch_time for select using (true);

-- Usuário só pode inserir/atualizar o próprio registro (para o mês atual)
drop policy if exists "Allow insert own monthly_watch_time" on public.monthly_watch_time;
create policy "Allow insert own monthly_watch_time"
  on public.monthly_watch_time for insert
  with check (auth.uid() = user_id and year_month = to_char(now(), 'YYYY-MM'));

drop policy if exists "Allow update own monthly_watch_time" on public.monthly_watch_time;
create policy "Allow update own monthly_watch_time"
  on public.monthly_watch_time for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- RPC: soma minutos no mês atual do usuário logado
-- =============================================================================
create or replace function public.add_monthly_watch_minutes(p_minutes integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_month text := to_char(now(), 'YYYY-MM');
begin
  if v_user_id is null or p_minutes is null or p_minutes < 1 then
    return;
  end if;
  insert into public.monthly_watch_time (user_id, year_month, watch_minutes)
  values (v_user_id, v_month, p_minutes)
  on conflict (user_id, year_month)
  do update set watch_minutes = monthly_watch_time.watch_minutes + EXCLUDED.watch_minutes;
end;
$$;

comment on function public.add_monthly_watch_minutes(integer) is 'Adiciona minutos assistidos ao mês atual do usuário (ranking global)';

-- =============================================================================
-- RPC: ranking global do mês atual (por tempo assistido)
-- Retorno: user_id, display_name, avatar_url, monthly_watch_hours, rank
-- =============================================================================
create or replace function public.get_global_ranking(
  limit_count int default 20,
  offset_count int default 0,
  search_text text default null
)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  monthly_watch_hours numeric,
  rank bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_month text := to_char(now(), 'YYYY-MM');
begin
  return query
  select t.user_id, t.display_name, t.avatar_url, t.monthly_watch_hours, t.rank
  from (
    select
      m.user_id,
      coalesce(p.display_name, 'Usuário')::text as display_name,
      p.avatar_url,
      (m.watch_minutes / 60.0)::numeric as monthly_watch_hours,
      row_number() over (order by m.watch_minutes desc) as rank
    from public.monthly_watch_time m
    left join public.user_profiles p on p.user_id = m.user_id
    where m.year_month = v_month
  ) t
  where (search_text is null or search_text = '' or t.display_name ilike '%' || search_text || '%')
  order by t.rank
  limit limit_count
  offset offset_count;
end;
$$;

comment on function public.get_global_ranking(int, int, text) is 'Ranking global do mês atual por tempo assistido (horas); search_text filtra por display_name';
