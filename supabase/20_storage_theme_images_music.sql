-- =============================================================================
-- Storage: buckets "theme-images" e "theme-music" para temas de perfil
-- Execute no Supabase: SQL Editor > New query > colar e Run.
--
-- Buckets para armazenar imagens (capa, preview) e músicas MP3 dos temas.
-- =============================================================================

-- 1) Criar bucket theme-images (para imagens de capa e preview dos temas)
-- IMPORTANTE: id e name devem ser iguais para o nome aparecer corretamente
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'theme-images',
  'theme-images',
  true,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  updated_at = now();

-- 2) Criar bucket theme-music (para músicas MP3 dos temas)
-- IMPORTANTE: id e name devem ser iguais para o nome aparecer corretamente
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'theme-music',
  'theme-music',
  true,
  52428800, -- 50MB
  ARRAY['audio/mpeg', 'audio/mp3']::text[]
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  updated_at = now();

-- 3) Políticas em storage.objects para theme-images
-- Leitura pública (qualquer um pode ver as imagens)
DROP POLICY IF EXISTS "Theme images: leitura pública" ON storage.objects;
CREATE POLICY "Theme images: leitura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'theme-images');

-- Upload: apenas usuários autenticados (admin pode fazer upload)
DROP POLICY IF EXISTS "Theme images: upload autenticado" ON storage.objects;
CREATE POLICY "Theme images: upload autenticado"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'theme-images'
    AND auth.role() = 'authenticated'
  );

-- Update/Delete: apenas usuários autenticados
DROP POLICY IF EXISTS "Theme images: update autenticado" ON storage.objects;
CREATE POLICY "Theme images: update autenticado"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'theme-images' AND auth.role() = 'authenticated')
  WITH CHECK (bucket_id = 'theme-images' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Theme images: delete autenticado" ON storage.objects;
CREATE POLICY "Theme images: delete autenticado"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'theme-images' AND auth.role() = 'authenticated');

-- 4) Políticas em storage.objects para theme-music
-- Leitura pública (qualquer um pode baixar as músicas)
DROP POLICY IF EXISTS "Theme music: leitura pública" ON storage.objects;
CREATE POLICY "Theme music: leitura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'theme-music');

-- Upload: apenas usuários autenticados (admin pode fazer upload)
DROP POLICY IF EXISTS "Theme music: upload autenticado" ON storage.objects;
CREATE POLICY "Theme music: upload autenticado"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'theme-music'
    AND auth.role() = 'authenticated'
  );

-- Update/Delete: apenas usuários autenticados
DROP POLICY IF EXISTS "Theme music: update autenticado" ON storage.objects;
CREATE POLICY "Theme music: update autenticado"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'theme-music' AND auth.role() = 'authenticated')
  WITH CHECK (bucket_id = 'theme-music' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Theme music: delete autenticado" ON storage.objects;
CREATE POLICY "Theme music: delete autenticado"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'theme-music' AND auth.role() = 'authenticated');

-- =============================================================================
-- INSTRUÇÕES:
-- 1. Execute este script no SQL Editor do Supabase
-- 2. Verifique se os buckets foram criados em Storage > Buckets
-- 3. Os buckets devem aparecer com os nomes: "theme-images" e "theme-music"
-- 4. Se já existirem buckets com nomes diferentes, delete-os primeiro pelo Dashboard
-- 5. Os buckets devem aparecer como públicos
-- 6. Agora você pode fazer upload de imagens e músicas MP3 pelo painel admin
-- =============================================================================
