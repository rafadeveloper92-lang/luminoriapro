# Cadastro Luminoria no site

Página de **registo e login** para o site [Luminoria](https://rafadeveloper92-lang.github.io/site/), usando o mesmo Supabase do app. Os utilizadores podem criar conta no site e depois entrar no app com o mesmo e-mail e senha.

## Segurança

- Usa apenas a **anon key** do Supabase, que é pensada para o frontend. Não coloque nunca a **service_role** key no site.
- A proteção dos dados é feita no Supabase com **Row Level Security (RLS)** e políticas de Auth.
- Senhas e sessões são geridas pelo Supabase Auth (igual ao app).

## Como usar no seu site GitHub Pages

### 1. Copiar ficheiros

Copie a pasta `site-cadastro` para o repositório do seu site (o que gera `rafadeveloper92-lang.github.io/site/`). Por exemplo:

- Coloque `index.html`, `config.example.js` e este `README.md` numa pasta (ex.: `cadastro` ou `registar`).
- No seu repo do site, a URL ficará algo como:  
  `https://rafadeveloper92-lang.github.io/site/cadastro/`  
  (conforme a estrutura do repo).

### 2. Configurar Supabase

1. Copie `config.example.js` para `config.js` (no mesmo sítio que o `index.html`).
2. Abra `config.js` e preencha:
   - **SUPABASE_URL:** o mesmo que está no `.env` do app (ex.: `https://xqcuoqerwrrpvxiwhjup.supabase.co`).
   - **SUPABASE_ANON_KEY:** a mesma **anon** key do app (em Supabase: Settings → API → `anon` public).

O `config.js` não deve ser commitado se não quiser expor a anon key no repositório; nesse caso pode usar variáveis de ambiente no GitHub Actions ao publicar o site. Para a maioria dos casos, ter a anon key no repo é aceitável (é a prática habitual com Supabase).

### 3. Confirmação de e-mail (opcional)

No Supabase: **Authentication** → **Providers** → **Email**:

- Se **Confirm email** estiver ativo, o utilizador recebe um link para confirmar. Pode definir **Redirect URL** para uma página do seu site (ex.: página de “Conta confirmada”).
- Se estiver desativado, o registo fica ativo logo após criar a conta.

### 4. Ligar no site principal

No site principal (landing), onde tem “Registo” ou “Criar conta”, use um link para esta página:

```html
<a href="/site/cadastro/">Criar conta</a>
```

(Ajuste o caminho conforme a estrutura do seu repo.)

## Estrutura

- `index.html` – página de registo e login (formulário + Supabase JS).
- `config.js` – URL e anon key (criar a partir de `config.example.js`).
- `config.example.js` – exemplo sem dados reais.

## Problemas comuns

- **"Configure SUPABASE_URL e SUPABASE_ANON_KEY"**  
  Verifique que `config.js` existe e define `window.SUPABASE_URL` e `window.SUPABASE_ANON_KEY` antes do script principal (o `index.html` carrega `config.js` no fim).

- **"User already registered"**  
  O e-mail já está registado; o utilizador deve usar “Entrar” ou recuperar a senha (no app ou por e-mail do Supabase, se configurado).

- **E-mail de confirmação não chega**  
  Em Supabase, verifique **Authentication** → **Email Templates** e, se usar domínio próprio, as definições de SMTP em **Project Settings** → **Auth**.
