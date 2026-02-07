# Configurar Storage manualmente no Dashboard (avatar e capa)

Faça tudo pelo Supabase Dashboard, sem depender do script SQL dos buckets.

---

## Parte 1 – Criar os buckets

### Bucket 1: user-avatars

1. Abra o [Supabase Dashboard](https://supabase.com/dashboard) e selecione o seu projeto.
2. No menu da esquerda, clique em **Storage**.
3. Clique no botão **New bucket**.
4. Preencha exatamente:
   - **Name:** `user-avatars`
   - **Public bucket:** ligado (ativado) — importante para o app exibir as imagens.
   - **File size limit:** `5` (significa 5 MB).
   - **Allowed MIME types:**  
     `image/jpeg`, `image/png`, `image/webp`, `image/gif`  
     (no formato que o Dashboard aceitar: um por linha ou separados por vírgula).
5. Clique em **Create bucket**.

### Bucket 2: user-covers

1. De novo em **Storage**, clique em **New bucket**.
2. Preencha:
   - **Name:** `user-covers`
   - **Public bucket:** ligado (ativado).
   - **File size limit:** `10` (10 MB).
   - **Allowed MIME types:**  
     `image/jpeg`, `image/png`, `image/webp`, `image/gif`
3. Clique em **Create bucket**.

Ao final você deve ver os dois buckets na lista: **user-avatars** e **user-covers**.

---

## Parte 2 – Políticas de segurança

Depois de criar os dois buckets, use **apenas** o SQL das políticas.

1. No menu da esquerda, abra **SQL Editor**.
2. Clique em **New query**.
3. Abra o arquivo **`supabase/10_storage_policies_avatars_covers.sql`** (só políticas, sem criar buckets).
4. Copie todo o conteúdo, cole no editor e clique em **Run**.

Se preferir criar as políticas pela interface em vez de SQL, use a Parte 3 abaixo.

---

## Parte 3 – Políticas pela interface (alternativa ao SQL)

Se o SQL das políticas também der erro, crie cada política no Dashboard.

1. Vá em **Storage**.
2. Clique no bucket (por exemplo **user-avatars**).
3. Abra a aba **Policies** (ou o ícone de escudo / “Policies” ao lado do bucket).
4. Clique em **New policy** e use um dos templates ou **For full customization** e preencha como abaixo.

Crie as políticas na tabela (os nomes podem ser iguais ou parecidos; o importante são as permissões e condições).

### Para o bucket **user-avatars**

| Nome (sugestão)     | Operation | Policy definition (USING / WITH CHECK) |
|---------------------|-----------|----------------------------------------|
| Leitura pública     | **SELECT** | `true` (ou deixar em branco se o bucket for público e a UI não exigir) |
| Upload na própria pasta | **INSERT** | **WITH CHECK:** `(storage.foldername(name))[1] = auth.uid()::text` |
| Update próprio      | **UPDATE** | **USING:** `(storage.foldername(name))[1] = auth.uid()::text` **WITH CHECK:** igual ao USING |
| Delete próprio      | **DELETE** | **USING:** `(storage.foldername(name))[1] = auth.uid()::text` |

### Para o bucket **user-covers**

| Nome (sugestão)     | Operation | Policy definition |
|---------------------|-----------|-------------------|
| Leitura pública     | **SELECT** | `true` |
| Upload na própria pasta | **INSERT** | **WITH CHECK:** `(storage.foldername(name))[1] = auth.uid()::text` |
| Update próprio      | **UPDATE** | **USING:** `(storage.foldername(name))[1] = auth.uid()::text` **WITH CHECK:** igual |
| Delete próprio      | **DELETE** | **USING:** `(storage.foldername(name))[1] = auth.uid()::text` |

Em algumas versões do Dashboard, as políticas são para **storage.objects** e você escolhe o bucket. Nesse caso, na condição você pode usar também `bucket_id = 'user-avatars'` ou `bucket_id = 'user-covers'` junto com a condição da pasta.

Exemplo para **INSERT** em **user-avatars**:

- **WITH CHECK:**  
  `bucket_id = 'user-avatars' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text`

---

## Conferência

- **Storage** → lista com **user-avatars** e **user-covers**, ambos **Public**.
- Em cada bucket, em **Policies**, as 4 políticas (SELECT, INSERT, UPDATE, DELETE) criadas.

Depois disso, no app (com usuário logado), teste trocar avatar e capa no perfil.
