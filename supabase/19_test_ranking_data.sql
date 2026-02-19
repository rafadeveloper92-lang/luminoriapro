-- =============================================================================
-- Script de TESTE: Insere dados fictícios no ranking global para o mês atual
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- 
-- Este script insere dados de teste na tabela monthly_watch_time para verificar
-- se o ranking global está funcionando corretamente.
-- 
-- IMPORTANTE: Este é um script de TESTE. Execute apenas para debug.
-- =============================================================================

-- Primeiro, vamos verificar se existem usuários na tabela auth.users
-- e criar dados de teste para eles no mês atual

-- Obter o mês atual no formato YYYY-MM
DO $$
DECLARE
  v_current_month text := to_char(now(), 'YYYY-MM');
  v_user_record record;
  v_counter int := 0;
BEGIN
  -- Limpar dados de teste anteriores do mês atual (opcional - descomente se quiser resetar)
  -- DELETE FROM public.monthly_watch_time WHERE year_month = v_current_month;
  
  -- Inserir dados de teste para os primeiros 10 usuários encontrados
  -- com diferentes quantidades de minutos assistidos para criar um ranking variado
  FOR v_user_record IN 
    SELECT id, email 
    FROM auth.users 
    ORDER BY created_at DESC 
    LIMIT 10
  LOOP
    -- Inserir dados de teste com diferentes valores de minutos
    -- O ranking será ordenado por watch_minutes DESC
    INSERT INTO public.monthly_watch_time (user_id, year_month, watch_minutes)
    VALUES (
      v_user_record.id,
      v_current_month,
      -- Valores variados: 1200 min (20h), 900 min (15h), 600 min (10h), etc.
      CASE v_counter
        WHEN 0 THEN 1200  -- 20 horas
        WHEN 1 THEN 900   -- 15 horas
        WHEN 2 THEN 600   -- 10 horas
        WHEN 3 THEN 480   -- 8 horas
        WHEN 4 THEN 360   -- 6 horas
        WHEN 5 THEN 240   -- 4 horas
        WHEN 6 THEN 180   -- 3 horas
        WHEN 7 THEN 120   -- 2 horas
        WHEN 8 THEN 60    -- 1 hora
        ELSE 30           -- 30 minutos
      END
    )
    ON CONFLICT (user_id, year_month) 
    DO UPDATE SET watch_minutes = EXCLUDED.watch_minutes;
    
    v_counter := v_counter + 1;
    
    RAISE NOTICE 'Inserido teste para usuário % (email: %): % minutos', 
      v_user_record.id, 
      v_user_record.email,
      CASE v_counter - 1
        WHEN 0 THEN 1200
        WHEN 1 THEN 900
        WHEN 2 THEN 600
        WHEN 3 THEN 480
        WHEN 4 THEN 360
        WHEN 5 THEN 240
        WHEN 6 THEN 180
        WHEN 7 THEN 120
        WHEN 8 THEN 60
        ELSE 30
      END;
  END LOOP;
  
  IF v_counter = 0 THEN
    RAISE NOTICE 'AVISO: Nenhum usuário encontrado na tabela auth.users. Crie alguns usuários primeiro.';
  ELSE
    RAISE NOTICE 'Sucesso: % registros de teste inseridos/atualizados para o mês %', v_counter, v_current_month;
  END IF;
END $$;

-- Verificar se os dados foram inseridos corretamente
SELECT 
  m.user_id,
  u.email,
  p.display_name,
  m.year_month,
  m.watch_minutes,
  ROUND(m.watch_minutes / 60.0, 2) as watch_hours,
  ROW_NUMBER() OVER (ORDER BY m.watch_minutes DESC) as rank
FROM public.monthly_watch_time m
LEFT JOIN auth.users u ON u.id = m.user_id
LEFT JOIN public.user_profiles p ON p.user_id = m.user_id
WHERE m.year_month = to_char(now(), 'YYYY-MM')
ORDER BY m.watch_minutes DESC
LIMIT 20;

-- Testar a função RPC get_global_ranking diretamente
SELECT * FROM public.get_global_ranking(20, 0, NULL);

-- =============================================================================
-- INSTRUÇÕES:
-- 1. Execute este script no SQL Editor do Supabase
-- 2. Verifique se aparecem mensagens de sucesso no console
-- 3. Verifique se a última query retorna dados
-- 4. Se retornar dados, o problema pode estar no código Flutter
-- 5. Se não retornar dados, verifique se:
--    - A migração 12_monthly_watch_time.sql foi executada
--    - Existem usuários na tabela auth.users
--    - As políticas RLS estão corretas
-- =============================================================================
