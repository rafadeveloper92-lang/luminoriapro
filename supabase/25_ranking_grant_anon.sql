-- =============================================================================
-- CORREÇÃO: Permite ao app (chave anon) chamar get_global_ranking.
-- Sem isto o ranking devolve 0 itens no app (no SQL Editor funciona porque é postgres).
-- Execute no Supabase SQL Editor e rode o app de novo.
-- =============================================================================

grant execute on function public.get_global_ranking(int, int, text) to anon;
grant execute on function public.get_global_ranking(int, int, text) to authenticated;
