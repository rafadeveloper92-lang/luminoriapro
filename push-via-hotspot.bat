@echo off
echo ========================================
echo   PUSH PARA GITHUB VIA HOTSPOT
echo ========================================
echo.
echo Verificando se esta conectado na internet...
ping google.com -n 2
echo.

cd /d C:\Users\rafaa\lotus\FlutterIPTV-main

echo Fazendo push para GitHub...
echo.
git push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================
    echo          SUCESSO! ^_^
    echo ========================================
    echo.
    echo Codigo enviado para GitHub!
    echo.
    echo Agora voce pode criar a release:
    echo   git tag v1.4.33
    echo   git push origin v1.4.33
    echo.
    echo Acesse: https://github.com/rafadeveloper92-lang/Luminoriadefinition
    echo.
) else (
    echo ========================================
    echo          ERRO
    echo ========================================
    echo.
    echo Se pedir usuario/senha:
    echo   Usuario: rafadeveloper92-lang
    echo   Senha: Use Personal Access Token
    echo.
    echo Gere token em: https://github.com/settings/tokens
    echo.
)
pause
