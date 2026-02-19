-- =============================================================================
-- Limpa TODOS os amigos e pedidos de amizade de TODOS os usuários
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Atenção: remove todas as relações de amizade do banco!
-- =============================================================================

TRUNCATE TABLE public.friends CASCADE;

TRUNCATE TABLE public.friend_requests CASCADE;
