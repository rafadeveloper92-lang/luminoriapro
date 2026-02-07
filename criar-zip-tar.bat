@echo off
echo ========================================
echo   CRIANDO ZIP SEGURO (SEM .env)
echo ========================================
echo.
echo IMPORTANTE: O .env NAO sera incluido (contem chaves secretas)
echo.
pause

cd /d C:\Users\rafaa\lotus\FlutterIPTV-main

echo Criando ZIP na Area de Trabalho...
echo Isso pode demorar alguns minutos...
echo.

REM Criar arquivo temporário com lista de arquivos
echo .github> include.txt
echo android>> include.txt
echo assets>> include.txt
echo docs>> include.txt
echo ios>> include.txt
echo lib>> include.txt
echo supabase>> include.txt
echo test>> include.txt
echo windows>> include.txt
echo .env.example>> include.txt
echo .gitignore>> include.txt
echo *.md>> include.txt
echo *.yaml>> include.txt
echo *.yml>> include.txt
echo *.json>> include.txt
echo *.dart>> include.txt
echo *.sh>> include.txt
echo *.ps1>> include.txt

REM Usar tar para criar o zip (disponível no Windows 10+)
tar -czf "%USERPROFILE%\Desktop\Luminoria-complete.zip" .github android assets docs ios lib supabase test windows .env.example .gitignore *.md *.yaml *.yml *.json *.dart *.sh *.ps1 2>nul

del include.txt 2>nul

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
    echo - .env.example (EXEMPLO)
    echo - Suas chaves reais estao SEGURAS
    echo.
    echo PROXIMOS PASSOS:
    echo 1. Va em: https://github.com/rafadeveloper92-lang/Luminoriadefinition
    echo 2. Clique: Add file - Upload files
    echo 3. Arraste: Luminoria-complete.zip
    echo 4. Escreva: "Upload codigo completo"
    echo 5. Commit changes
    echo.
) else (
    echo ERRO: Nao foi possivel criar o ZIP
    echo.
    echo Tente instalar 7-Zip ou use o Windows Explorer:
    echo 1. Selecione as pastas no Explorer
    echo 2. Clique direito - Enviar para - Pasta compactada
)

pause
