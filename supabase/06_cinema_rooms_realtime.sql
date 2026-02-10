-- =============================================================================
-- Ativar Supabase Realtime (Postgres Changes) na tabela cinema_rooms
-- Necessário para sincronização play/pause/seek entre host e participantes.
--
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Alternativa: Dashboard > Database > Replication > adicione cinema_rooms à publicação supabase_realtime
--
-- Nota: Se a tabela já estiver na publicação, o comando pode retornar erro - isso é normal.
-- =============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.cinema_rooms;
