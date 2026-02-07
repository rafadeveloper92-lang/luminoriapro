# 🤖 GitHub Actions - Guia Completo

## 📋 Workflows Configurados

O projeto agora tem 3 workflows do GitHub Actions configurados:

### 1. **Build and Release** (`build-release.yml`)
- **Quando executa**: Push de tags (v1.0.0) ou manualmente
- **O que faz**: Compila Windows, Android (Mobile + TV) e iOS
- **Resultado**: Cria release no GitHub com todos os arquivos

### 2. **Build Test** (`test-build.yml`)
- **Quando executa**: Todo push/PR nas branches main/develop
- **O que faz**: Testa se o código compila em todas as plataformas
- **Resultado**: Valida o código sem criar release

### 3. **Build iOS Signed** (`build-ios-signed.yml`) - Opcional
- **Quando executa**: Manualmente
- **O que faz**: Compila iOS com assinatura de código
- **Resultado**: IPA assinado pronto para distribuição/TestFlight

---

## 🚀 Como Usar

### Método 1: Criar Release Automático (Recomendado)

```bash
# 1. Commit suas mudanças
git add .
git commit -m "Nova versão com suporte iOS"

# 2. Criar e fazer push da tag
git tag v1.4.33
git push origin v1.4.33

# 3. O GitHub Actions irá automaticamente:
#    - Compilar Windows, Android e iOS
#    - Criar release com todos os arquivos
#    - Gerar notas de release
```

### Método 2: Build Manual

1. Vá para o GitHub: `Actions` → `Build and Release`
2. Clique em `Run workflow`
3. Digite a versão (ex: 1.4.33)
4. Clique em `Run workflow`

### Método 3: Build de Teste (sem release)

- Apenas faça push para `main` ou `develop`
- O workflow `Build Test` irá validar automaticamente

---

## 📦 Resultado dos Builds

Após a execução bem-sucedida, você terá:

### Windows
- `flutteriptv-Windows-x64-Setup.exe` - Instalador para Windows

### Android Mobile
- `flutteriptv-Android-Mobile-arm64-v8a.apk` - 64-bit ARM (recomendado)
- `flutteriptv-Android-Mobile-armeabi-v7a.apk` - 32-bit ARM
- `flutteriptv-Android-Mobile-x86_64.apk` - x86_64 (emuladores)

### Android TV
- `flutteriptv-AndroidTV-arm64-v8a.apk` - 64-bit ARM (recomendado)
- `flutteriptv-AndroidTV-armeabi-v7a.apk` - 32-bit ARM
- `flutteriptv-AndroidTV-x86_64.apk` - x86_64 (emuladores)

### iOS
- `flutteriptv-iOS-unsigned.ipa` - IPA não assinado

---

## 🍎 iOS: Como Instalar o IPA Não Assinado

O IPA gerado não tem assinatura da Apple. Para instalá-lo:

### Opção 1: AltStore (Recomendado)
1. Baixe [AltStore](https://altstore.io/)
2. Instale no seu Mac/PC
3. Conecte o iPhone via USB
4. Arraste o IPA para o AltStore
5. Renovar a cada 7 dias (conta gratuita)

### Opção 2: Sideloadly
1. Baixe [Sideloadly](https://sideloadly.io/)
2. Conecte o iPhone
3. Arraste o IPA
4. Faça login com Apple ID
5. Renovar a cada 7 dias

### Opção 3: Xcode (requer Mac)
1. Abra Xcode
2. Window → Devices and Simulators
3. Conecte o iPhone
4. Arraste o IPA para a lista de apps

### Opção 4: Configurar Assinatura Automática (Avançado)
Veja a seção "Configurar Assinatura iOS" abaixo.

---

## 🔐 Configurar Secrets (Opcional)

### Para Android (Assinatura de APK)

Se você tiver uma keystore, configure:

1. Vá em: `Settings` → `Secrets and variables` → `Actions`
2. Adicione os secrets:

```
KEYSTORE_BASE64: (base64 do arquivo release-key.jks)
KEYSTORE_PASSWORD: senha da keystore
KEY_PASSWORD: senha da key
KEY_ALIAS: alias da key
```

**Como gerar o base64:**
```bash
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release-key.jks"))

# Linux/Mac
base64 -i release-key.jks -o keystore.txt
```

### Para iOS (Assinatura de IPA) - Avançado

⚠️ **Requer conta Apple Developer ($99/ano)**

1. Exporte o certificado do Keychain como .p12
2. Baixe o Provisioning Profile (.mobileprovision)
3. Configure os secrets:

```
IOS_P12_CERTIFICATE: (base64 do arquivo .p12)
IOS_P12_PASSWORD: senha do .p12
IOS_PROVISIONING_PROFILE: (base64 do .mobileprovision)
KEYCHAIN_PASSWORD: qualquer senha temporária
APP_STORE_CONNECT_API_KEY: (opcional, para TestFlight)
```

**Como usar:**
1. Vá em: `Actions` → `Build iOS with Code Signing`
2. `Run workflow`
3. Escolha o tipo: `development`, `adhoc` ou `appstore`

---

## 🔧 Personalizar os Workflows

### Alterar versão do Flutter

Edite a linha no workflow:

```yaml
env:
  FLUTTER_VERSION: '3.38.5'  # Alterar aqui
```

### Adicionar mais arquiteturas Android

```yaml
- name: Build APK
  run: flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64
```

### Mudar nome dos arquivos

Altere nas linhas de `cp` nos workflows:

```yaml
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk dist/SEU-NOME-AQUI.apk
```

---

## 📊 Monitorar os Builds

1. Vá em: `Actions` no GitHub
2. Clique no workflow em execução
3. Veja os logs de cada job (Windows, Android, iOS)
4. Download dos artifacts se necessário

---

## ❓ Solução de Problemas

### Build do iOS falha

**Problema:** "CocoaPods install failed"
```yaml
# Adicione antes do pod install:
- name: Update CocoaPods repo
  run: pod repo update
```

**Problema:** "Flutter version not found"
```yaml
# Use versão específica:
flutter-version: '3.19.0'  # ao invés de '3.38.5'
```

### Build do Android falha

**Problema:** "Keystore not found"
- Os secrets KEYSTORE_* são opcionais
- Remova a seção "Setup Android Signing" se não tiver keystore

**Problema:** "Gradle timeout"
```yaml
# Adicione mais timeout:
- name: Build Android
  run: flutter build apk --release
  timeout-minutes: 30
```

### Build do Windows falha

**Problema:** "Inno Setup not found"
- O Inno Setup está pré-instalado no runner
- Se falhar, remova a seção "Create Installer"

---

## 🎯 Próximos Passos

### Imediato (Grátis)
1. ✅ Push do código para GitHub
2. ✅ Criar tag para gerar release automático
3. ✅ Baixar IPA e instalar com AltStore/Sideloadly

### Futuro (Requer Apple Developer)
1. Comprar conta Apple Developer ($99/ano)
2. Criar certificados e provisioning profiles
3. Configurar workflow de assinatura
4. Publicar na App Store

---

## 📚 Recursos

- [GitHub Actions - Flutter](https://docs.github.com/en/actions)
- [Flutter Build iOS](https://docs.flutter.dev/deployment/ios)
- [AltStore](https://altstore.io/)
- [Sideloadly](https://sideloadly.io/)
- [Apple Developer](https://developer.apple.com/)

---

## 🆘 Suporte

Se tiver problemas:
1. Verifique os logs do workflow no GitHub Actions
2. Teste localmente: `flutter build ios --release --no-codesign`
3. Verifique se todas as dependências estão no pubspec.yaml
4. Confirme que o Podfile está correto

