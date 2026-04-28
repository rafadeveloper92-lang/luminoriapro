-- =============================================================================
-- RPC atómico: incrementar XP e horas assistidas (evita corrida no cliente ao
-- gravar user_profiles e apagar avatar_url / XP por upsert com estado velho).
-- Execute após 08_user_profiles_xp_genres.sql
-- =============================================================================

create or replace function public.increment_xp_from_watch(p_minutes integer)
returns public.user_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_hours numeric;
  v_row public.user_profiles;
begin
  if p_minutes is null or p_minutes < 1 then
    select * into v_row from public.user_profiles where user_id = auth.uid();
    return v_row;
  end if;

  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  v_hours := (p_minutes::numeric / 60.0);

  update public.user_profiles
  set
    xp = coalesce(xp, 0) + p_minutes,
    watch_hours = coalesce(watch_hours, 0) + v_hours,
    updated_at = now()
  where user_id = v_uid
  returning * into v_row;

  if not found then
    insert into public.user_profiles (user_id, xp, watch_hours, updated_at)
    values (v_uid, p_minutes, v_hours, now())
    returning * into v_row;
  end if;

  return v_row;
end;
$$;

comment on function public.increment_xp_from_watch(integer) is
  'Soma XP (1 por minuto) e watch_hours no servidor; evita lost updates no upsert do cliente.';

revoke all on function public.increment_xp_from_watch(integer) from public;
grant execute on function public.increment_xp_from_watch(integer) to authenticated;
