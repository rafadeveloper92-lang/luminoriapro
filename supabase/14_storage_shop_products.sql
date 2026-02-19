-- =============================================================================
-- Storage: bucket "shop-products" para imagens dos produtos da loja (admin)
-- Execute no Supabase: SQL Editor > New query > colar e Run.
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  gen_random_uuid(),
  'shop-products',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (name) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  updated_at = now();

-- Leitura pública (qualquer um pode ver imagens dos produtos)
DROP POLICY IF EXISTS "Shop products: leitura pública" ON storage.objects;
CREATE POLICY "Shop products: leitura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'shop-products');

-- Apenas admins podem fazer upload
DROP POLICY IF EXISTS "Shop products: admin upload" ON storage.objects;
CREATE POLICY "Shop products: admin upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'shop-products'
    AND auth.role() = 'authenticated'
    AND exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- Apenas admins podem atualizar ou apagar
DROP POLICY IF EXISTS "Shop products: admin update" ON storage.objects;
CREATE POLICY "Shop products: admin update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'shop-products'
    AND exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  WITH CHECK (bucket_id = 'shop-products');

DROP POLICY IF EXISTS "Shop products: admin delete" ON storage.objects;
CREATE POLICY "Shop products: admin delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'shop-products'
    AND exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );
