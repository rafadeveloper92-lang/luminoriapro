-- =============================================================================
-- RPC: admin_add_coins — permite ao admin adicionar moedas à conta de um usuário.
-- Execute após 02_admins, 13_shop_coins_products_orders.
-- =============================================================================

create or replace function public.admin_add_coins(p_user_id uuid, p_amount integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;
  if not exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email')) then
    raise exception 'Only admins can add coins';
  end if;
  update public.user_profiles
  set coins = coins + p_amount,
      updated_at = now()
  where user_id = p_user_id;
  if not found then
    raise exception 'User profile not found for user_id %', p_user_id;
  end if;
end;
$$;

comment on function public.admin_add_coins(uuid, integer) is 'Adiciona moedas à conta de um usuário; apenas admins';

grant execute on function public.admin_add_coins(uuid, integer) to authenticated;
