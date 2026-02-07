# Passo a passo: configurar Stripe (Luminoria)

Você vai configurar em **dois lugares**:

| Onde | O que |
|------|--------|
| **Arquivo `.env`** (na raiz do projeto) | Chaves que o **app Flutter** usa (públicas + IDs de produto/preço). |
| **Supabase** (secrets das Edge Functions) | Chaves **secretas** que só o servidor usa (criar checkout, receber webhook). |

O **STRIPE_PRICE_ID** deve ser o **mesmo** no `.env` e no Supabase.

---

## Parte 1 — Stripe Dashboard (pegar as chaves)

1. Acesse [Stripe Dashboard](https://dashboard.stripe.com) e faça login.
2. Use **Test mode** (toggle no canto superior) para testes.
3. **API Keys**
   - Vá em **Developers** → **API keys**.
   - Copie:
     - **Publishable key** (começa com `pk_test_...` ou `pk_live_...`) → vai no **.env**.
     - **Secret key** (começa com `sk_test_...` ou `sk_live_...`) → vai no **Supabase** (secret).
4. **Produto e preço**
   - Vá em **Product catalog** → **Products** → crie um produto (ex.: "Assinatura 1 ano") ou use um existente.
   - No produto, crie ou escolha um **Price** (ex.: valor único, 1 ano).
   - Copie:
     - **Product ID** (ex.: `prod_...`) → opcional, vai no **.env** (só para exibir no painel admin).
     - **Price ID** (ex.: `price_...`) → vai no **.env** e no **Supabase**.

---

## Parte 2 — Configurar o app: arquivo `.env`

1. Na **raiz do projeto** (pasta onde está o `pubspec.yaml`), copie o exemplo:
   - Copie `.env.example` para um arquivo chamado `.env`.
2. Abra o `.env` e preencha as linhas do Stripe:

```env
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
STRIPE_PRICE_ID=price_xxxxxxxxxxxx
STRIPE_PRODUCT_ID=prod_xxxxxxxxxxxx
```

3. Salve. O app usa essas variáveis para:
   - Saber se o Stripe está configurado (botão "Assinar" aparece).
   - Mostrar Product ID e Price ID no painel admin.
   - Chamar a Edge Function que cria o checkout (a URL do Supabase já vem do `SUPABASE_URL` do `.env`).

**Importante:** não coloque a **Secret key** (`sk_...`) no `.env` — ela não pode ficar no app.

---

## Parte 3 — Configurar o Supabase (Edge Functions)

As Edge Functions **create-checkout** e **stripe-webhook** rodam no Supabase e precisam de **secrets**.

1. Acesse [Supabase](https://supabase.com) → seu projeto.
2. Vá em **Project Settings** (ícone de engrenagem) → **Edge Functions**.
3. Na seção **Secrets**, adicione:

| Nome do secret | Valor |
|----------------|--------|
| `STRIPE_SECRET_KEY` | A **Secret key** do Stripe (`sk_test_...` ou `sk_live_...`). |
| `STRIPE_PRICE_ID` | O **mesmo** Price ID que você colocou no `.env` (ex.: `price_...`). |
| `STRIPE_WEBHOOK_SIGNING_SECRET` | Você vai preencher depois de criar o webhook (Parte 4). |

4. **⚠️ Deploy obrigatório das Edge Functions**  
   Só configurar os secrets **não basta**. Se as funções não forem publicadas no projeto, o app dá **erro 404** ao clicar em "Assinar Agora". Em **qualquer** máquina ou clone novo do projeto, é preciso fazer o deploy:

   - Instale o [Supabase CLI](https://supabase.com/docs/guides/cli) se ainda não tiver.
   - No terminal, na **raiz do projeto** (pasta do `pubspec.yaml`):
     ```bash
     supabase login
     supabase link --project-ref SEU_PROJECT_REF
     supabase functions deploy create-checkout --no-verify-jwt
     supabase functions deploy stripe-webhook --no-verify-jwt
     ```
     (Troque `SEU_PROJECT_REF` pelo Reference ID do projeto: Supabase Dashboard → Settings → General.)
     O `--no-verify-jwt` evita erro **401** ao clicar em "Assinar" (a função pode ser chamada com a anon key; a chave secreta do Stripe fica só no servidor).
   - Depois disso o botão "Assinar" deixa de dar 404 e 401.

---

## Parte 4 — Webhook no Stripe (para liberar licença após o pagamento)

O Stripe envia o evento "pagamento concluído" para o Supabase; a função **stripe-webhook** atualiza a tabela `licenses`.

1. No **Stripe Dashboard** → **Developers** → **Webhooks** → **Add endpoint**.
2. **Endpoint URL:**
   - `https://<SEU-PROJETO>.supabase.co/functions/v1/stripe-webhook`
   - Troque `<SEU-PROJETO>` pelo **Reference ID** do projeto no Supabase (Settings → General → Reference ID).
3. **Events to send:** selecione **checkout.session.completed**.
4. Clique em **Add endpoint**.
5. Na página do endpoint, em **Signing secret**, clique em **Reveal** e copie o valor (começa com `whsec_...`).
6. No **Supabase** → **Project Settings** → **Edge Functions** → **Secrets**, adicione (ou edite):
   - Nome: `STRIPE_WEBHOOK_SIGNING_SECRET`
   - Valor: o `whsec_...` que você copiou.

---

## Resumo rápido

- **.env (raiz do projeto):** `STRIPE_PUBLISHABLE_KEY`, `STRIPE_PRICE_ID`, `STRIPE_PRODUCT_ID` (opcional).
- **Supabase → Edge Functions → Secrets:** `STRIPE_SECRET_KEY`, `STRIPE_PRICE_ID`, `STRIPE_WEBHOOK_SIGNING_SECRET`.
- **Deploy obrigatório:** `supabase login` → `supabase link --project-ref XXX` → `supabase functions deploy create-checkout` (e `stripe-webhook`). Sem isso, o app dá **404** ao assinar.
- **Stripe → Webhooks:** endpoint apontando para `.../stripe-webhook`, evento `checkout.session.completed`, e o signing secret no Supabase.

Depois disso, no app: tela de bloqueio → **Assinar (Stripe)** → pagamento no navegador → voltar ao app → a licença é verificada de novo e o conteúdo é liberado.
