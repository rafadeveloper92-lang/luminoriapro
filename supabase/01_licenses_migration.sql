-- =============================================================================
-- Migração: se você JÁ criou a tabela licenses antes (só device_id),
-- execute este arquivo para adicionar user_id e tornar device_id opcional.
-- Se for instalação nova, use apenas 01_licenses.sql.
-- =============================================================================

-- Adiciona coluna user_id (uma licença por usuário)
alter table public.licenses add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.licenses alter column device_id drop not null;

-- Índice e unique (só um registro por user_id)
create unique index if not exists idx_licenses_user_id_unique on public.licenses (user_id) where user_id is not null;
