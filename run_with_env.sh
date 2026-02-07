#!/usr/bin/env bash
# Lê o arquivo .env na raiz do projeto e roda o Flutter com as variáveis.
# Uso: ./run_with_env.sh
# O .env deve estar na mesma pasta que o pubspec.yaml (raiz do projeto).

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Arquivo .env não encontrado em: $ENV_FILE"
  echo "Copie .env.example para .env e preencha suas chaves."
  echo "Exemplo: cp .env.example .env"
  exit 1
fi

set -a
source <(grep -v '^#' "$ENV_FILE" | grep -v '^\s*$' | sed 's/^/export /')
set +a

DART_DEFINES=()
[ -n "$SUPABASE_URL" ] && DART_DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
[ -n "$SUPABASE_ANON_KEY" ] && DART_DEFINES+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
[ -n "$TMDB_API_KEY" ] && DART_DEFINES+=(--dart-define=TMDB_API_KEY="$TMDB_API_KEY")

cd "$SCRIPT_DIR"
exec flutter run "${DART_DEFINES[@]}" "$@"
