-- =============================================================================
-- Ativar Supabase Realtime (Postgres Changes) para chat direto e solicitações de amizade
-- Necessário para: mensagens em tempo real no chat entre amigos e badge de solicitações na lista de amigos.
--
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Se a tabela já estiver na publicação, o comando pode retornar erro - pode ignorar.
-- =============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friend_requests;
