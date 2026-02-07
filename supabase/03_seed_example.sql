-- =============================================================================
-- Exemplos de dados (opcional)
-- Use após criar o usuário no app (cadastro) e obter o user_id no Supabase.
-- =============================================================================

-- Inserir seu email como administrador (substitua pelo email real)
-- insert into public.admins (email) values ('seu@email.com');

-- Inserir licença para um USUÁRIO (user_id = id do auth.users)
-- O user_id você obtém em: Supabase > Authentication > Users > copiar o UUID do usuário.
-- Exemplo: ativar por 1 ano para o usuário com id 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
-- insert into public.licenses (user_id, expires_at, plan, notes)
-- values ('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', now() + interval '1 year', '1y', 'Cliente João - Plano Anual');

-- Exemplo: ativar por 30 dias
-- insert into public.licenses (user_id, expires_at, plan, notes)
-- values ('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', now() + interval '30 days', '30d', 'Cliente teste');
