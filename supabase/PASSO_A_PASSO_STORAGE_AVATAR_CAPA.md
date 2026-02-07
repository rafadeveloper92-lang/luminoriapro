# Passo a passo: Buckets Supabase para avatar e capa

O app usa dois buckets no Supabase Storage:
- **user-avatars** → fotos de avatar do perfil
- **user-covers** → fotos de capa do perfil

---

## Opção 1 – Executar o SQL (recomendado)

1. Acesse o [Supabase Dashboard](https://supabase.com/dashboard) e abra o seu projeto.
2. No menu lateral, clique em **SQL Editor**.
3. Clique em **New query**.
4. Abra o arquivo `supabase/09_storage_buckets_avatars_covers.sql` do projeto, copie **todo** o conteúdo e cole no editor.
5. Clique em **Run** (ou Ctrl+Enter).
6. Confirme que aparece mensagem de sucesso (e nenhum erro em vermelho).
7. Vá em **Storage** no menu lateral: devem aparecer os buckets **user-avatars** e **user-covers**.

Pronto. As políticas de segurança já ficam criadas pelo script.

---

## Opção 2 – Criar pelos buckets e políticas na interface

Se preferir criar tudo pela interface:

### 1. Criar o bucket **user-avatars**

1. No Supabase Dashboard, vá em **Storage**.
2. Clique em **New bucket**.
3. Preencha:
   - **Name:** `user-avatars`
   - **Public bucket:** ative (marcado), para o app poder usar a URL pública da imagem.
   - **File size limit:** `5` MB.
   - **Allowed MIME types:** `image/jpeg`, `image/png`, `image/webp`, `image/gif` (um por linha ou separados por vírgula, conforme o campo).
4. Clique em **Create bucket**.

### 2. Criar o bucket **user-covers**

1. De novo em **New bucket**.
2. Preencha:
   - **Name:** `user-covers`
   - **Public bucket:** ative (marcado).
   - **File size limit:** `10` MB.
   - **Allowed MIME types:** `image/jpeg`, `image/png`, `image/webp`, `image/gif`.
3. Clique em **Create bucket**.

### 3. Políticas de segurança (RLS)

No Supabase, as políticas de Storage são em **Storage** → **Policies** (ou via SQL). O jeito mais seguro e completo é usar o SQL do passo a passo abaixo.

1. Vá em **SQL Editor** → **New query**.
2. Cole **apenas** o bloco de políticas (parte 3 do arquivo `09_storage_buckets_avatars_covers.sql`), ou seja, a partir de:

```sql
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
```

3. Clique em **Run**.

---

## O que as políticas fazem

| Política | O que permite |
|----------|----------------|
| **Leitura pública** | Qualquer um (incluindo app sem login) pode **ler** arquivos em `user-avatars` e `user-covers` (necessário para exibir avatar/capa em perfis e listas). |
| **Avatar/Capa: upload na própria pasta** | Só usuário **autenticado** pode fazer **upload** em arquivos cuja pasta é o próprio `auth.uid()` (ex.: `userId/avatar_123.jpg`). |
| **Update/Delete próprio** | Só o dono (pasta = `auth.uid()`) pode **atualizar** ou **apagar** seus arquivos. |

---

## Resumo rápido

- **Mais simples:** use a **Opção 1** e rode o `09_storage_buckets_avatars_covers.sql` inteiro no SQL Editor.
- Depois, em **Storage**, confira se **user-avatars** e **user-covers** existem e estão públicos.
- No app, faça login e teste trocar avatar e capa no perfil; se der erro de política, confira se o usuário está logado via Supabase (mesma conta do AdminAuthService).
