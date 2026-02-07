# SQL do Supabase (Luminoria)

Scripts para configurar as tabelas e políticas no Supabase. Execute na **ordem** no **SQL Editor** do seu projeto (Supabase Dashboard → SQL Editor → New query).

## Fluxo do app

1. **Splash** → se não estiver logado: **Login/Cadastro**; se já logado: **Verificação de licença**.
2. **Login ou Cadastro** (e-mail + senha, Supabase Auth) → após sucesso vai para a verificação de licença.
3. **Verificação de licença** por **user_id** (conta logada): se tiver licença ativa → **Home**; senão → tela de bloqueio (e-mail + link WhatsApp).
4. Licença é **uma por usuário** (id único por conta), mais seguro.

## Ordem de execução

| Arquivo | O que faz |
|---------|-----------|
| **01_licenses.sql** | Cria a tabela `licenses` com **user_id** (uuid, único, referência auth.users), expires_at, plan, notes e RLS. |
| **02_admins.sql** | Cria a tabela `admins` (email) e RLS para o usuário verificar se o próprio email é admin. |
| **03_seed_example.sql** | Opcional: exemplos de `INSERT` para admin e licenças por user_id. |
| **04_support_tickets.sql** | Cria a tabela `support_tickets` (chamados de suporte: utilizadores enviam da app, admin vê no painel). |

Se você **já tinha** a tabela `licenses` antiga (só device_id), use **01_licenses_migration.sql** em vez de criar de novo.

## Passo a passo

1. Acesse [Supabase](https://supabase.com) → seu projeto.
2. **Authentication** → **Providers** → **Email**: ative "Enable Email provider" (login/cadastro por e-mail).
3. **SQL Editor** → **New query** → cole **01_licenses.sql** → **Run**.
4. Nova query → cole **02_admins.sql** → **Run**.
5. (Opcional) Em **03_seed_example.sql**, descomente e ajuste os `INSERT` que quiser, depois execute.

## Criar o usuário administrador (painel admin no app)

1. **Authentication** → **Users** → **Add user** (e-mail + senha).
2. No SQL Editor:  
   `insert into public.admins (email) values ('seu@email.com');`  
   (use o mesmo e-mail do usuário criado.)

## Ativar uma licença (novo cliente)

O cliente **cadastra-se** no app (e-mail + senha). Depois você ativa a licença pelo **user_id** dele:

1. No Supabase: **Authentication** → **Users** → copie o **UUID** do usuário (coluna "UID" ou "id").
2. No SQL Editor:
   - **30 dias:**  
     `insert into public.licenses (user_id, expires_at, plan, notes) values ('uuid-do-usuario', now() + interval '30 days', '30d', 'Nome do cliente');`
   - **1 ano:**  
     `insert into public.licenses (user_id, expires_at, plan, notes) values ('uuid-do-usuario', now() + interval '1 year', '1y', 'Nome do cliente');`

Ou use o **Painel Administrativo** no app (Configurações → Entrar como administrador) para editar assinaturas e datas.

---

## Stripe (pagamentos)

**Passo a passo completo:** veja **[STRIPE_SETUP.md](../STRIPE_SETUP.md)** na raiz do projeto (configuração no **.env** + **Supabase** + webhook no Stripe).

Resumo: configure o **.env** (app) e os **secrets** no Supabase (Edge Functions). **Importante:** é obrigatório fazer o **deploy** das Edge Functions (`create-checkout` e `stripe-webhook`) com o Supabase CLI — só secrets não basta; sem o deploy o app dá **404** ao clicar em Assinar.

### Edge Functions

- **create-checkout**: recebe `device_id` e opcional `user_id`, cria sessão do Stripe Checkout e devolve a URL.
- **stripe-webhook**: recebe o webhook do Stripe (`checkout.session.completed`, `invoice.paid`, `invoice.payment_failed`), atualiza a tabela `licenses` e regista eventos em `payment_events` para o painel admin.

### Secrets (Supabase Dashboard → Project Settings → Edge Functions → Secrets)

| Secret | Descrição |
|--------|-----------|
| `STRIPE_SECRET_KEY` | Chave secreta da API do Stripe (ex.: `sk_live_...` ou `sk_test_...`). |
| `STRIPE_PRICE_ID` | ID do preço no Stripe (ex.: `price_...`). Deve ser o mesmo usado no `.env` do app (`STRIPE_PRICE_ID`). |
| `STRIPE_WEBHOOK_SIGNING_SECRET` | Signing secret do endpoint de webhook no Stripe (ex.: `whsec_...`). |

### Webhook no Stripe

1. No [Stripe Dashboard](https://dashboard.stripe.com) → **Developers** → **Webhooks** → **Add endpoint**.
2. **Endpoint URL**: `https://<seu-projeto>.supabase.co/functions/v1/stripe-webhook` (troque `<seu-projeto>` pelo ID do projeto Supabase).
3. **Events to send**: selecione `checkout.session.completed`, `invoice.paid` e `invoice.payment_failed` (para histórico de pagamentos e falhas no painel admin).
4. Depois de criar, copie o **Signing secret** e defina como `STRIPE_WEBHOOK_SIGNING_SECRET` nos secrets da Edge Function.

### URLs de sucesso/cancelamento

O checkout usa URLs placeholder; o app faz **refresh da licença ao voltar** (resume). Se quiser deep link, altere `success_url` e `cancel_url` na Edge Function **create-checkout** para o seu scheme (ex.: `lotusiptv://stripe-success` e `lotusiptv://cancel`).
