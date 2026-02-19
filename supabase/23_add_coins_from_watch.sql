-- =============================================================================
-- RPC: add_coins_from_watch — adiciona moedas ao usuário logado por minutos
-- assistidos em filme/série (1 moeda por minuto). Chamado pelo app ao reportar
-- sessão de VOD. Execute após 13_shop_coins_products_orders.
-- =============================================================================

create or replace function public.add_coins_from_watch(p_minutes integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;
  if p_minutes is null or p_minutes < 1 then
    return;
  end if;
  -- Limite por chamada para evitar abuso (máx. 120 min = 2h por reporte)
  if p_minutes > 120 then
    raise exception 'Max 120 minutes per call';
  end if;
  update public.user_profiles
  set coins = coins + p_minutes,
      updated_at = now()
  where user_id = v_user_id;
end;
$$;

comment on function public.add_coins_from_watch(integer) is 'Adiciona moedas ao usuário logado: 1 moeda por minuto assistido (filme/série)';

grant execute on function public.add_coins_from_watch(integer) to authenticated;
