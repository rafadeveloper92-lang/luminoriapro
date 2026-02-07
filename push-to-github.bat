@echo off
echo ========================================
echo   SCRIPT DE PUSH PARA GITHUB
echo ========================================
echo.
echo Este script vai enviar seu codigo para o GitHub
echo.
echo IMPORTANTE: Se estiver usando VPN ou Proxy, desative temporariamente!
echo.
pause

echo.
echo Verificando conexao com GitHub...
ping github.com -n 2

echo.
echo Tentando push...
git push -u origin main

echo.
echo ========================================
if %ERRORLEVEL% EQU 0 (
    echo SUCESSO! Codigo enviado para GitHub!
    echo.
    echo Acesse: https://github.com/rafadeveloper92-lang/Luminoriadefinition
    echo.
) else (
    echo ERRO! Nao foi possivel conectar ao GitHub.
    echo.
    echo Solucoes:
    echo 1. Desative VPN/Proxy e tente novamente
    echo 2. Use um Personal Access Token como senha
    echo 3. Configure chave SSH
    echo.
    echo Para gerar Personal Access Token:
    echo https://github.com/settings/tokens
    echo.
)
echo ========================================
pause
