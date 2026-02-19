-- =============================================================================
-- Contagem de amigos para exibição no perfil de qualquer usuário
-- RLS em friends só permite ver linhas onde auth.uid() = user_id; ao visitar
-- o perfil de outro usuário a contagem retornava 0. Esta função (SECURITY DEFINER)
-- retorna apenas o número, sem expor a lista de amigos.
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- =============================================================================

create or replace function public.get_friend_count(target_user_id uuid)
returns int
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::int from public.friends where user_id = target_user_id;
$$;

comment on function public.get_friend_count(uuid) is 'Retorna a quantidade de amigos do usuário (para exibir no perfil público).';

grant execute on function public.get_friend_count(uuid) to authenticated;
-- Não conceder a anon: rede premium só para usuários autenticados.
