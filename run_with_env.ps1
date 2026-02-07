# Lê o arquivo .env na raiz do projeto e roda o Flutter com as variáveis.
# Uso: .\run_with_env.ps1
# O .env deve estar na mesma pasta que o pubspec.yaml (raiz do projeto).

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "Arquivo .env nao encontrado em: $envFile" -ForegroundColor Yellow
    Write-Host "Copie .env.example para .env e preencha suas chaves." -ForegroundColor Yellow
    Write-Host "Exemplo: Copy-Item .env.example .env" -ForegroundColor Gray
    exit 1
}

$vars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
        $key = $matches[1]
        $val = $matches[2].Trim().Trim('"').Trim("'")
        $vars[$key] = $val
    }
}

$dartDefines = @()
if ($vars.ContainsKey('SUPABASE_URL')) { $dartDefines += "--dart-define=SUPABASE_URL=$($vars['SUPABASE_URL'])" }
if ($vars.ContainsKey('SUPABASE_ANON_KEY')) { $dartDefines += "--dart-define=SUPABASE_ANON_KEY=$($vars['SUPABASE_ANON_KEY'])" }
if ($vars.ContainsKey('TMDB_API_KEY')) { $dartDefines += "--dart-define=TMDB_API_KEY=$($vars['TMDB_API_KEY'])" }

Set-Location $PSScriptRoot
& flutter run @dartDefines @args
