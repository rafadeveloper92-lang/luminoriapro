-- =============================================================================
-- DIAGNÓSTICO: Ranking global vazio
-- Execute no Supabase SQL Editor e confira os resultados.
-- =============================================================================

-- 1) Quantos perfis existem? (Se 0, o ranking fica vazio até alguém ter perfil.)
SELECT COUNT(*) AS total_user_profiles FROM public.user_profiles;

-- 2) Chamar a função como o app chama (deve devolver até 20 linhas se houver perfis):
SELECT * FROM public.get_global_ranking(20, 0, NULL);

-- Se (1) der 0 → crie perfis (usuários precisam abrir o app e ter perfil criado).
-- Se (1) der > 0 e (2) devolver 0 linhas → a função get_global_ranking pode ser a antiga: execute 24_global_ranking_all_users.sql de novo.
