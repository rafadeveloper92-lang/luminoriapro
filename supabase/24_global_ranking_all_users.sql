-- =============================================================================
-- Ranking global: listar TODOS os usuários cadastrados (user_profiles) e ordenar
-- por minutos/horas assistidos no mês atual. Quem não tem minutos no mês aparece
-- com 0 horas no fim da lista. Execute após 12_monthly_watch_time.sql.
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
      p.user_id,
      coalesce(nullif(trim(p.display_name), ''), 'Usuário')::text as display_name,
      p.avatar_url,
      (coalesce(m.watch_minutes, 0) / 60.0)::numeric as monthly_watch_hours,
      row_number() over (order by coalesce(m.watch_minutes, 0) desc, p.updated_at desc) as rank
    from public.user_profiles p
    left join public.monthly_watch_time m on m.user_id = p.user_id and m.year_month = v_month
  ) t
  where (search_text is null or search_text = '' or t.display_name ilike '%' || search_text || '%')
  order by t.rank
  limit limit_count
  offset offset_count;
end;
$$;

comment on function public.get_global_ranking(int, int, text) is 'Ranking global: todos os usuários cadastrados, ordenados por horas assistidas no mês atual (0 = fim da lista)';

-- Permite ao app (anon e authenticated) chamar a função. Sem isto o ranking devolve 0 itens no app.
grant execute on function public.get_global_ranking(int, int, text) to anon;
grant execute on function public.get_global_ranking(int, int, text) to authenticated;
