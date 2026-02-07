@echo off
echo ========================================
echo   CRIANDO ZIP PARA UPLOAD MANUAL
echo ========================================
echo.
echo Criando arquivo ZIP otimizado...
echo Excluindo: build, .git, arquivos grandes
echo.

cd /d C:\Users\rafaa\lotus\FlutterIPTV-main

powershell -Command "Compress-Archive -Path * -DestinationPath 'C:\Users\rafaa\Desktop\Luminoria-code.zip' -Force -Exclude @('build/*','.git/*','*.db','pubspec.lock','*.log')"

echo.
if exist "C:\Users\rafaa\Desktop\Luminoria-code.zip" (
    echo ========================================
    echo SUCESSO!
    echo ========================================
    echo.
    echo Arquivo criado em: C:\Users\rafaa\Desktop\Luminoria-code.zip
    echo.
    echo PROXIMOS PASSOS:
    echo 1. Va em: https://github.com/rafadeveloper92-lang/Luminoriadefinition
    echo 2. Clique: "uploading an existing file"
    echo 3. Arraste o ZIP ou selecione ele
    echo 4. Escreva: "Upload codigo completo"
    echo 5. Clique: "Commit changes"
    echo.
) else (
    echo ERRO ao criar ZIP
)

pause
