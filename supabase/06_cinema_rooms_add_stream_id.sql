-- =============================================================================
-- Migração: Adiciona coluna stream_id à tabela cinema_rooms
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- Esta coluna permite registrar filmes assistidos na Cinema Room no histórico.
-- =============================================================================

-- Adiciona coluna stream_id se ela não existir
alter table public.cinema_rooms
  add column if not exists stream_id text;

comment on column public.cinema_rooms.stream_id is 'ID do stream do filme/série para registro no histórico';

-- Cria índice para consultas por stream_id (opcional, mas útil)
create index if not exists idx_cinema_rooms_stream_id on public.cinema_rooms (stream_id);
