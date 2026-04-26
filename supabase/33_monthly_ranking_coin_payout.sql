-- =============================================================================
-- Prémios do ranking mensal: creditar moedas (user_profiles.coins) no fecho do mês
-- Execute após 24_global_ranking_all_users.sql, 13_shop_coins_products_orders.sql.
--
-- 1) Tabela monthly_ranking_rewards — registo idempotente (evita duplicar crédito)
-- 2) rank_reward_coins(rank) — mesmos valores que GlobalRankPrizes no app (11–1000: 15; >1000: 0)
-- 3) apply_monthly_ranking_rewards(year_month) — paga o mês indicado ou o mês UTC anterior se null
-- 4) pg_cron (opcional): dia 1 às 00:10 UTC — ative a extensão em Database > Extensions
-- =============================================================================

-- Moedas por posição (manter alinhado com lib/features/rank/constants/global_rank_prizes.dart)
create or replace function public.rank_reward_coins(p_rank integer)
returns integer
language sql
immutable
parallel safe
as $$
  select case
    when p_rank is null or p_rank < 1 then 0
    when p_rank = 1 then 500
    when p_rank = 2 then 300
    when p_rank = 3 then 150
    when p_rank = 4 then 100
    when p_rank = 5 then 75
    when p_rank = 6 then 60
    when p_rank = 7 then 50
    when p_rank = 8 then 40
    when p_rank = 9 then 30
    when p_rank = 10 then 25
    when p_rank <= 1000 then 15
    else 0
  end;
$$;

comment on function public.rank_reward_coins(integer) is 'Moedas do ranking mensal por posição (1–10 escalonado; 11–1000: 15; >1000: 0)';

create table if not exists public.monthly_ranking_rewards (
  year_month text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  rank integer not null check (rank >= 1),
  coins_awarded integer not null check (coins_awarded >= 0),
  created_at timestamptz not null default now(),
  primary key (year_month, user_id)
);

comment on table public.monthly_ranking_rewards is 'Crédito de moedas por ranking mensal já aplicado (idempotente por mês/utilizador)';

create index if not exists idx_monthly_ranking_rewards_year_month on public.monthly_ranking_rewards(year_month);
create index if not exists idx_monthly_ranking_rewards_user on public.monthly_ranking_rewards(user_id);

alter table public.monthly_ranking_rewards enable row level security;

drop policy if exists "User read own monthly_ranking_rewards" on public.monthly_ranking_rewards;
create policy "User read own monthly_ranking_rewards"
  on public.monthly_ranking_rewards for select
  using (auth.uid() = user_id);

-- Apenas sistema (sem policy de insert para utilizadores — inserções via SECURITY DEFINER)

create or replace function public.apply_monthly_ranking_rewards(p_year_month text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_year_month text;
begin
  if p_year_month is null or length(trim(p_year_month)) = 0 then
    v_year_month := to_char(
      (date_trunc('month', timezone('utc', now())) - interval '1 month')::date,
      'YYYY-MM'
    );
  else
    v_year_month := trim(p_year_month);
    if v_year_month !~ '^\d{4}-\d{2}$' then
      raise exception 'Invalid year_month (use YYYY-MM): %', p_year_month;
    end if;
  end if;

  return (
    with ranked as (
      select
        m.user_id,
        row_number() over (
          order by m.watch_minutes desc, p.updated_at desc nulls last, m.user_id
        )::integer as rk
      from public.monthly_watch_time m
      inner join public.user_profiles p on p.user_id = m.user_id
      where m.year_month = v_year_month
        and m.watch_minutes > 0
    ),
    to_award as (
      select r.user_id, r.rk as rank, public.rank_reward_coins(r.rk) as coins
      from ranked r
      where public.rank_reward_coins(r.rk) > 0
    ),
    ins as (
      insert into public.monthly_ranking_rewards (year_month, user_id, rank, coins_awarded)
      select v_year_month, t.user_id, t.rank, t.coins
      from to_award t
      on conflict (year_month, user_id) do nothing
      returning user_id, coins_awarded
    ),
    upd as (
      update public.user_profiles up
      set
        coins = up.coins + i.coins_awarded,
        updated_at = now()
      from ins i
      where up.user_id = i.user_id
      returning up.user_id
    )
    select jsonb_build_object(
      'year_month', v_year_month,
      'profiles_credited', (select count(*)::int from ins),
      'total_coins_awarded', (select coalesce(sum(coins_awarded), 0)::bigint from ins),
      'profiles_updated', (select count(*)::int from upd)
    )
  );
end;
$$;

comment on function public.apply_monthly_ranking_rewards(text) is
  'Credita moedas do ranking do mês fechado (UTC). p_year_month null = mês anterior. Idempotente.';

revoke all on function public.apply_monthly_ranking_rewards(text) from public;
grant execute on function public.apply_monthly_ranking_rewards(text) to service_role;

-- Opcional: agendar (extensão pg_cron — Database > Extensions > pg_cron ON)
-- Dia 1 de cada mês, 00:10 UTC (após virar o mês)
do $cron$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid)
    from cron.job
    where jobname = 'apply_monthly_ranking_rewards';
    perform cron.schedule(
      'apply_monthly_ranking_rewards',
      '10 0 1 * *',
      $cmd$select public.apply_monthly_ranking_rewards(null);$cmd$
    );
  end if;
exception
  when undefined_object then
    null;
  when undefined_table then
    null;
end;
$cron$;
