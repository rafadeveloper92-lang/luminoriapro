@echo off
echo ========================================
echo   CRIANDO ZIP SEGURO (SEM .env)
echo ========================================
echo.
echo IMPORTANTE: O .env NAO sera incluido (contem chaves secretas)
echo O arquivo .env.example sera incluido como referencia
echo.
pause

cd /d C:\Users\rafaa\lotus\FlutterIPTV-main

echo Criando ZIP na Area de Trabalho...
echo Isso pode demorar alguns minutos...
echo.

powershell -Command "Compress-Archive -Path '.github','android','assets','docs','ios','lib','supabase','test','windows','.env.example','*.md','*.yaml','*.yml','*.json','*.dart','*.sh','*.ps1','.gitignore','devtools_options.yaml','flutter_launcher_icons.yaml','analysis_options.yaml' -DestinationPath '%USERPROFILE%\Desktop\Luminoria-complete.zip' -Force"

if exist "%USERPROFILE%\Desktop\Luminoria-complete.zip" (
    echo.
    echo ========================================
    echo          SUCESSO!
    echo ========================================
    echo.
    echo ZIP criado em: Desktop\Luminoria-complete.zip
    echo.
    echo O que foi incluido:
    echo - Todas as pastas do projeto
    echo - .env.example (EXEMPLO, nao suas chaves reais)
    echo - Seus arquivos .env estao SEGUROS (nao foram incluidos)
    echo.
    echo PROXIMOS PASSOS:
    echo 1. Va em: https://github.com/rafadeveloper92-lang/Luminoriadefinition
    echo 2. Clique: Add file ^> Upload files
    echo 3. Arraste o ZIP: Luminoria-complete.zip
    echo 4. Escreva: "Upload codigo completo"
    echo 5. Commit changes
    echo.
    echo Depois vou te ensinar a configurar as chaves como GitHub Secrets!
    echo.
) else (
    echo ERRO: Nao foi possivel criar o ZIP
)

pause
