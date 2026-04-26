-- =============================================================================
-- Indicador público "é administrador" no perfil (sem expor a tabela admins)
-- A app chama RPC com o user_id do perfil visitado; retorna true se o email
-- desse utilizador (auth.users) consta em public.admins.
-- Execute no Supabase: SQL Editor > Run (após 02_admins.sql).
-- =============================================================================

create or replace function public.is_admin_user(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public, auth
stable
as $$
  select coalesce(
    exists (
      select 1
      from public.admins a
      inner join auth.users u on lower(trim(both from u.email)) = lower(trim(both from a.email))
      where u.id = p_user_id
        and u.email is not null
        and length(trim(both from u.email)) > 0
    ),
    false
  );
$$;

comment on function public.is_admin_user(uuid) is 'True se o utilizador é administrador (email em public.admins); para badge no perfil.';

revoke all on function public.is_admin_user(uuid) from public;
grant execute on function public.is_admin_user(uuid) to authenticated;
