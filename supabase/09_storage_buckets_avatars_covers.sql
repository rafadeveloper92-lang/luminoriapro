-- =============================================================================
-- Storage: buckets "user-avatars" e "user-covers" para avatar e capa do perfil
-- Execute no Supabase: SQL Editor > New query > colar e Run.
--
-- Nomes alternativos (user-avatars, user-covers) para evitar conflito com
-- nomes reservados ou buckets existentes.
-- =============================================================================

-- 1) Criar bucket user-avatars
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  gen_random_uuid(),
  'user-avatars',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (name) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  updated_at = now();

-- 2) Criar bucket user-covers
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  gen_random_uuid(),
  'user-covers',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (name) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  updated_at = now();

-- 3) Políticas em storage.objects
DROP POLICY IF EXISTS "Avatar e capa: leitura pública" ON storage.objects;
CREATE POLICY "Avatar e capa: leitura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id IN ('user-avatars', 'user-covers'));

DROP POLICY IF EXISTS "Avatar: upload na própria pasta" ON storage.objects;
CREATE POLICY "Avatar: upload na própria pasta"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user-avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Covers: upload na própria pasta" ON storage.objects;
CREATE POLICY "Covers: upload na própria pasta"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user-covers'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Avatar: update próprio" ON storage.objects;
CREATE POLICY "Avatar: update próprio"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Avatar: delete próprio" ON storage.objects;
CREATE POLICY "Avatar: delete próprio"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'user-avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Covers: update próprio" ON storage.objects;
CREATE POLICY "Covers: update próprio"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'user-covers' AND auth.uid()::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'user-covers' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Covers: delete próprio" ON storage.objects;
CREATE POLICY "Covers: delete próprio"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'user-covers' AND auth.uid()::text = (storage.foldername(name))[1]);

-- =============================================================================
-- Após rodar: Storage > Files deve mostrar "user-avatars" e "user-covers"
-- Limites: 5MB avatars, 10MB covers
-- =============================================================================
