# Configuração Supabase (chaves seguras)

As chaves do Supabase **não ficam no código** nem no repositório. Elas são passadas em **tempo de compilação** via `--dart-define`, assim o app fica seguro e você pode usar sua key sem expô-la.

## 1. Obter URL e Anon Key

No [Supabase](https://supabase.com): seu projeto → **Settings** → **API**.

- **Project URL** → use em `SUPABASE_URL`
- **Project API keys** → **anon public** → use em `SUPABASE_ANON_KEY`

Nunca use a chave **service_role** no app (só em backend).

## 2. Rodar o app (desenvolvimento)

Passe as variáveis na linha de comando:

```bash
flutter run --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Usando um arquivo .env (opcional, só no seu PC)

1. Crie um arquivo `.env` na raiz do projeto (ele já está no `.gitignore`):

   ```
   SUPABASE_URL=https://SEU_PROJETO.supabase.co
   SUPABASE_ANON_KEY=sua_anon_key_aqui
   ```

2. Rode com um dos exemplos abaixo.

**PowerShell (Windows):**
```powershell
$env:SUPABASE_URL = (Get-Content .env | Where-Object { $_ -match '^SUPABASE_URL=' }) -replace 'SUPABASE_URL=', ''
$env:SUPABASE_ANON_KEY = (Get-Content .env | Where-Object { $_ -match '^SUPABASE_ANON_KEY=' }) -replace 'SUPABASE_ANON_KEY=', ''
flutter run --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

**Git Bash / WSL / Linux / macOS:**
```bash
export $(grep -v '^#' .env | xargs)
flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

## 3. Gerar build (release)

Para APK, App Bundle, Windows etc., use os mesmos `--dart-define`:

```bash
flutter build apk --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=sua_anon_key
```

Em **CI/CD** (GitHub Actions, Codemagic, etc.), use variáveis secretas do ambiente e passe para o Flutter:

```yaml
flutter build apk \
  --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
  --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

## 4. Conferir se está configurado

Se **não** passar `SUPABASE_URL` e `SUPABASE_ANON_KEY`, o app abre normalmente, mas:

- a tela de ativação por licença fica bloqueada (sem conexão com o Supabase);
- o login de administrador e o painel admin não funcionam.

Ou seja: sem as variáveis, o app roda; com elas, licença e admin passam a funcionar.

## Resumo

| Onde        | O que fazer |
|------------|-------------|
| Código     | Nada: não coloque URL nem key no código. |
| Repositório| Nada: não commite `.env` nem arquivos com keys. |
| Sua máquina| Use `.env` (opcional) ou variáveis de ambiente. |
| Build/CI    | Use `--dart-define=SUPABASE_URL=...` e `--dart-define=SUPABASE_ANON_KEY=...`. |

Assim a key fica só com você e nos seus pipelines de build, e o app continua seguro.
