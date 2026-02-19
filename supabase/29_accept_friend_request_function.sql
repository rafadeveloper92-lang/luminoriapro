-- =============================================================================
-- Aceitar pedido de amizade em uma única transação (evita amizade só de um lado).
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- =============================================================================

create or replace function public.accept_friend_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_from_id uuid;
  v_to_id uuid;
begin
  -- Busca o pedido (só o destinatário pode aceitar)
  select from_user_id, to_user_id
  into v_from_id, v_to_id
  from public.friend_requests
  where id = p_request_id and to_user_id = auth.uid();
  if v_from_id is null or v_to_id is null then
    return false;
  end if;
  -- Insere as duas linhas em friends (ignora se já existir)
  insert into public.friends (user_id, friend_user_id)
  values (v_to_id, v_from_id)
  on conflict (user_id, friend_user_id) do nothing;
  insert into public.friends (user_id, friend_user_id)
  values (v_from_id, v_to_id)
  on conflict (user_id, friend_user_id) do nothing;
  -- Remove o pedido
  delete from public.friend_requests where id = p_request_id;
  return true;
end;
$$;

comment on function public.accept_friend_request(uuid) is 'Aceita um pedido de amizade em transação (insere ambas as linhas em friends e remove o pedido).';

grant execute on function public.accept_friend_request(uuid) to authenticated;
