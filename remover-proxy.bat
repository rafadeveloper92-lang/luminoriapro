@echo off
echo ========================================
echo   REMOVER PROXY DO GIT
echo ========================================
echo.
echo IMPORTANTE: Execute este arquivo como ADMINISTRADOR
echo (Clique com botao direito e escolha "Executar como administrador")
echo.
pause

echo Removendo configuracoes de proxy...
git config --system --unset-all http.proxy
git config --system --unset-all https.proxy
git config --global --unset-all http.proxy
git config --global --unset-all https.proxy
git config --local --unset-all http.proxy
git config --local --unset-all https.proxy

echo.
echo Verificando...
git config --list | findstr proxy

echo.
echo ========================================
echo Proxy removido!
echo ========================================
echo.
echo Agora execute: push-via-hotspot.bat
echo.
pause
