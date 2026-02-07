@echo off
echo ========================================
echo   CRIANDO ZIP SEGURO (SEM .env)
echo ========================================
echo.

cd /d C:\Users\rafaa\lotus\FlutterIPTV-main

echo Criando ZIP na Area de Trabalho...
echo.

tar -czf "%USERPROFILE%\Desktop\Luminoria-complete.zip" .github android assets docs ios lib supabase test windows .env.example .gitignore *.md *.yaml *.yml *.json *.sh *.ps1 2>nul

if exist "%USERPROFILE%\Desktop\Luminoria-complete.zip" (
    echo ========================================
    echo          SUCESSO!
    echo ========================================
    echo.
    echo ZIP criado: Desktop\Luminoria-complete.zip
    echo.
    echo Agora:
    echo 1. Abra: https://github.com/rafadeveloper92-lang/Luminoriadefinition
    echo 2. Add file - Upload files
    echo 3. Arraste: Luminoria-complete.zip
    echo 4. Commit changes
    echo.
) else (
    echo ERRO: Nao conseguiu criar ZIP
)
