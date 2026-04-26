-- Início da reprodução atual (para "Assistindo · Há X min" sem confundir com o ping de presença).
-- Execute no Supabase: SQL Editor > Run.
ALTER TABLE public.user_status
  ADD COLUMN IF NOT EXISTS playing_started_at timestamptz;

COMMENT ON COLUMN public.user_status.playing_started_at IS 'Quando começou a reprodução atual (playing_content); atualizado ao mudar de conteúdo';
