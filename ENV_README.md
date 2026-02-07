# Onde criar o arquivo .env e como usar

Todas as chaves (Supabase e TMDB) ficam **fora do código**, em um único arquivo `.env`.

## Onde criar o .env

O arquivo `.env` fica na **raiz do projeto**, na **mesma pasta que o `pubspec.yaml`**.

Exemplo de estrutura:

```
FlutterIPTV-main/
├── pubspec.yaml
├── .env          ← crie aqui (ou copie de .env.example)
├── .env.example  ← modelo (pode commitar)
├── lib/
├── run_with_env.ps1
└── run_with_env.sh
```

Caminho completo no seu PC (exemplo):

- **Windows:** `c:\Users\rafaa\lotus\FlutterIPTV-main\.env`
- Ou seja: a pasta onde está o `pubspec.yaml` = mesma pasta do `.env`.

## Passo a passo

1. **Copie o modelo para .env**
   - Na raiz do projeto (pasta do `pubspec.yaml`):
   - Copie o arquivo `.env.example` e renomeie a cópia para `.env`.

2. **Abra o .env e preencha**
   - `SUPABASE_URL` – do Supabase (Settings > API > Project URL)
   - `SUPABASE_ANON_KEY` – do Supabase (Settings > API > anon public)
   - `TMDB_API_KEY` – de https://www.themoviedb.org/settings/api

3. **Nunca commite o .env**
   - O `.env` já está no `.gitignore`; não envie esse arquivo para o Git.

4. **Rodar o app**
   - Depois de criar o `.env` uma vez, use **`flutter run`** ou o **Run/Play** no IDE. O app carrega o `.env` sozinho — **não precisa do script** `run_with_env.ps1`.

**Para o app carregar o .env ao abrir** (e não precisar do script): depois de criar o `.env`, adicione-o aos assets do Flutter. No `pubspec.yaml`, na seção `flutter:` → `assets:`, inclua a linha `- .env` (por exemplo logo após `- assets/sql/`). Salve e rode de novo. Se não fizer isso, o app abre mas as chaves vêm vazias (use o script `run_with_env.ps1` para passar as chaves).

## Build (APK, etc.)

Com o `.env` criado e preenchido, use **`flutter build apk`** (ou o botão de build do IDE). O app usa as chaves do `.env` da mesma forma que no `flutter run`.

## Resumo

| O que        | Onde / como |
|-------------|-------------|
| **Criar .env** | Na **raiz do projeto** (mesma pasta do `pubspec.yaml`). Uma vez só. |
| **Conteúdo**  | Copiar de `.env.example` e preencher Supabase + TMDB. |
| **Rodar app** | `flutter run` ou Run/Play no IDE — **não precisa de script**. |
| **Não commitar** | `.env` já está no `.gitignore`. |

Assim todas as chaves ficam só no seu `.env` e nada fica no código.
