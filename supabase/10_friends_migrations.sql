-- =============================================================================
-- Migrações para correção de bugs no sistema de amigos
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- =============================================================================

-- 1. Permitir status 'offline' em user_status (app usa setUserStatus('offline') no lifecycle)
-- O check original só tinha ('online', 'busy', 'invisible'); 'offline' era rejeitado.
ALTER TABLE public.user_status DROP CONSTRAINT IF EXISTS user_status_status_check;
ALTER TABLE public.user_status ADD CONSTRAINT user_status_status_check 
  CHECK (status IN ('online', 'busy', 'invisible', 'offline'));

-- 2. Permitir que ao aceitar pedido de amizade, o aceitador insira a linha recíproca (amigo vê eu)
-- RLS original só permitia auth.uid() = user_id; ao aceitar, precisamos inserir (requester_id, acceptor_id)
-- para que o requester veja o aceitador como amigo.
DROP POLICY IF EXISTS "Allow CRUD own friends" ON public.friends;
CREATE POLICY "Allow CRUD own friends"
  ON public.friends FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    OR (
      auth.uid() = friend_user_id
      AND EXISTS (
        SELECT 1 FROM public.friend_requests
        WHERE from_user_id = user_id AND to_user_id = friend_user_id
      )
    )
  );
