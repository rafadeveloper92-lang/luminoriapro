-- =============================================================================
-- Remove os dados de TESTE do ranking (inseridos pelo 19_test_ranking_data.sql).
-- As horas voltam a ser só as que o app reportou ao assistir.
-- Execute no Supabase SQL Editor quando quiser "zerar" o ranking do mês atual.
-- =============================================================================

-- Opção A: Zera os minutos do mês atual (todos ficam com 0 h até assistirem de novo)
UPDATE public.monthly_watch_time
SET watch_minutes = 0
WHERE year_month = to_char(now(), 'YYYY-MM');

-- Opção B (alternativa): Remove todas as linhas do mês atual.
-- Descomente a linha abaixo e comente o UPDATE acima se preferir apagar em vez de zerar.
-- DELETE FROM public.monthly_watch_time WHERE year_month = to_char(now(), 'YYYY-MM');

-- Confirma: mostra quantos registos ficaram para o mês atual
SELECT year_month, COUNT(*) as usuarios, SUM(watch_minutes) as total_minutos
FROM public.monthly_watch_time
WHERE year_month = to_char(now(), 'YYYY-MM')
GROUP BY year_month;
