-- =============================================================================
-- SÓ POLÍTICAS DE STORAGE (sem criar buckets)
-- Use este arquivo DEPOIS de criar os buckets "user-avatars" e "user-covers"
-- manualmente no Dashboard (Storage > New bucket).
-- Execute: SQL Editor > New query > colar e Run.
-- =============================================================================

-- Leitura pública para os dois buckets (qualquer um pode ver as imagens)
DROP POLICY IF EXISTS "Avatar e capa: leitura pública" ON storage.objects;
CREATE POLICY "Avatar e capa: leitura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id IN ('user-avatars', 'user-covers'));

-- Avatar: só usuário autenticado pode fazer upload na pasta do próprio userId
DROP POLICY IF EXISTS "Avatar: upload na própria pasta" ON storage.objects;
CREATE POLICY "Avatar: upload na própria pasta"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user-avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Capa: mesmo para user-covers
DROP POLICY IF EXISTS "Covers: upload na própria pasta" ON storage.objects;
CREATE POLICY "Covers: upload na própria pasta"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user-covers'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Avatar: só o dono pode atualizar ou apagar
DROP POLICY IF EXISTS "Avatar: update próprio" ON storage.objects;
CREATE POLICY "Avatar: update próprio"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Avatar: delete próprio" ON storage.objects;
CREATE POLICY "Avatar: delete próprio"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Capa: só o dono pode atualizar ou apagar
DROP POLICY IF EXISTS "Covers: update próprio" ON storage.objects;
CREATE POLICY "Covers: update próprio"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'user-covers' AND auth.uid()::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'user-covers' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Covers: delete próprio" ON storage.objects;
CREATE POLICY "Covers: delete próprio"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'user-covers' AND auth.uid()::text = (storage.foldername(name))[1]);
