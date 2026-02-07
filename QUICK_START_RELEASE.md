# 🚀 Guia Rápido: Publicar Release com iOS

## Passo 1: Commit e Push do Código

```bash
# Adicionar todos os arquivos (incluindo configuração iOS)
git add .

# Commit das mudanças
git commit -m "Adicionar suporte iOS e GitHub Actions"

# Push para o GitHub
git push origin main
```

## Passo 2: Criar e Publicar Tag de Release

```bash
# Criar tag com a versão (exemplo: v1.4.33)
git tag v1.4.33

# Enviar a tag para o GitHub
git push origin v1.4.33
```

## Passo 3: Aguardar o Build Automático

1. Acesse: `https://github.com/SEU-USUARIO/FlutterIPTV/actions`
2. O workflow "Build and Release" será executado automaticamente
3. Aguarde ~20-30 minutos (build em 3 plataformas)
4. Veja o progresso em tempo real nos logs

## Passo 4: Download dos Arquivos

Após o build completar:

1. Acesse: `https://github.com/SEU-USUARIO/FlutterIPTV/releases`
2. Você verá a release `v1.4.33`
3. Baixe os arquivos:
   - Windows: `flutteriptv-Windows-x64-Setup.exe`
   - Android Mobile: `flutteriptv-Android-Mobile-arm64-v8a.apk`
   - Android TV: `flutteriptv-AndroidTV-arm64-v8a.apk`
   - **iOS**: `flutteriptv-iOS-unsigned.ipa`

---

## 📱 Como Instalar o iOS no iPhone

### Método AltStore (Mais Fácil)

1. **Instale o AltStore no PC:**
   - Windows: https://altstore.io/
   - Mac: https://altstore.io/
   
2. **Configure:**
   - Instale o iTunes (Windows) ou tenha macOS atualizado
   - Conecte o iPhone via USB
   - Abra o AltStore no PC
   - Faça login com seu Apple ID
   
3. **Instale o App:**
   - Baixe o arquivo `flutteriptv-iOS-unsigned.ipa`
   - Arraste o IPA para o ícone do AltStore na bandeja do sistema
   - Aguarde a instalação
   - No iPhone: Settings → General → Device Management
   - Confie no seu Apple ID

4. **Renovação:**
   - Apps precisam ser renovados a cada 7 dias
   - O AltStore faz isso automaticamente se estiver no mesmo WiFi

### Método Sideloadly (Alternativa)

1. **Baixe e instale:** https://sideloadly.io/
2. Conecte o iPhone via USB
3. Arraste o IPA para o Sideloadly
4. Faça login com Apple ID
5. Clique em "Start"
6. Confie no certificado no iPhone

---

## 🎯 Verificar Status do Build

### Via GitHub Web:
```
https://github.com/SEU-USUARIO/FlutterIPTV/actions
```

### Via Terminal (GitHub CLI):
```bash
# Instalar GitHub CLI: https://cli.github.com/
gh run list --workflow="build-release.yml"
gh run view --log
```

---

## ⚠️ Solução de Problemas

### "Build do iOS falhou"
- Verifique os logs no GitHub Actions
- Geralmente é problema de CocoaPods
- O workflow tenta resolver automaticamente

### "Não consigo instalar o IPA"
- Certifique-se de que é o arquivo `.ipa` (não `.zip`)
- Verifique se o iPhone está em modo Desenvolvedor
- Settings → Privacy & Security → Developer Mode → ON

### "App fecha imediatamente"
- Vá em Settings → General → VPN & Device Management
- Confie no perfil do desenvolvedor

---

## 🔄 Build Manual (sem tag)

Se quiser testar sem criar release:

1. Vá em: https://github.com/SEU-USUARIO/FlutterIPTV/actions
2. Clique em "Build and Release"
3. Clique em "Run workflow"
4. Digite a versão: `1.4.33`
5. Clique em "Run workflow"
6. Os artifacts ficarão disponíveis para download (não cria release público)

---

## 📊 Exemplo de Timeline

```
0 min  - Push da tag
1 min  - GitHub Actions detecta e inicia
5 min  - Build Windows completo ✓
15 min - Build Android completo ✓
25 min - Build iOS completo ✓
26 min - Release criado automaticamente ✓
```

---

## 🎉 Pronto!

Agora seu app Luminoria IPTV funciona em:
- ✅ Windows
- ✅ Android Mobile
- ✅ Android TV / Smart TV
- ✅ iPhone / iPad

Tudo compilado automaticamente no GitHub Actions! 🚀

