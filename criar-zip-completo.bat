@echo off
echo ========================================
echo   CRIANDO ZIP COMPLETO PARA GITHUB
echo ========================================
echo.

cd /d C:\Users\rafaa\lotus\FlutterIPTV-main

echo Criando ZIP na Area de Trabalho...
echo Isso pode demorar alguns minutos...
echo.

powershell -Command "Compress-Archive -Path '.github','android','assets','docs','ios','lib','supabase','test','windows','*.md','*.yaml','*.yml','*.json','*.dart','*.sh','*.ps1','*.bat' -DestinationPath '%USERPROFILE%\Desktop\Luminoria-complete.zip' -Force"

if exist "%USERPROFILE%\Desktop\Luminoria-complete.zip" (
    echo.
    echo ========================================
    echo          SUCESSO!
    echo ========================================
    echo.
    echo ZIP criado em: Desktop\Luminoria-complete.zip
    echo.
    echo PROXIMOS PASSOS:
    echo 1. Va em: https://github.com/rafadeveloper92-lang/Luminoriadefinition
    echo 2. Clique: Add file ^> Upload files
    echo 3. Arraste o ZIP: Luminoria-complete.zip
    echo 4. Escreva: "Upload codigo completo com pastas"
    echo 5. Commit changes
    echo.
    echo O GitHub vai extrair o ZIP automaticamente!
    echo.
) else (
    echo ERRO: Nao foi possivel criar o ZIP
)

pause
