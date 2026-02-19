-- =============================================================================
-- Ativar Supabase Realtime (Postgres Changes) para chat direto, solicitações de amizade e status dos amigos.
-- Necessário para: mensagens em tempo real, badge de solicitações e lista de amigos atualizando (online/offline, Assistindo).
-- Inclui: direct_messages, friend_requests, user_status, user_profiles, friends (lista de amigos em tempo real).
--
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Se a tabela já estiver na publicação, o comando pode retornar erro - pode ignorar.
-- =============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friend_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_status;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friends;
