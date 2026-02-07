# 📱 Configuração iOS - Luminoria IPTV

## ✅ O que foi configurado

1. **Estrutura iOS criada** com `flutter create --platforms=ios`
2. **Info.plist configurado** com:
   - Nome do app alterado para "Luminoria"
   - Permissões de rede local (NSLocalNetworkUsageDescription)
   - Suporte a HTTP não seguro (NSAppTransportSecurity)
   - Serviços Bonjour para DLNA
   - Background modes para áudio
   - WiFi persistente habilitado
   - Embedded views para video players
3. **Podfile criado** com configurações otimizadas
4. **Ícones habilitados** no flutter_launcher_icons.yaml

---

## ⚠️ Dependências que podem precisar de ajustes no iOS

### 🎥 Video Players
- `media_kit` e `media_kit_video` - **Verificar compatibilidade com iOS**
- `media_kit_libs_windows_video` - ❌ Não funciona no iOS (apenas Windows)
- `media_kit_libs_android_video` - ❌ Não funciona no iOS (apenas Android)
- `video_player` - ✅ Funciona no iOS

**Recomendação:** Usar `video_player` nativo do Flutter para iOS, ou verificar se `media_kit` tem suporte iOS.

### 🗄️ Banco de Dados
- `sqflite` - ✅ Funciona no iOS
- `sqflite_common_ffi` - ⚠️ Pode ter limitações no iOS (é para desktop)

### 🪟 Window Management
- `window_manager` - ❌ Não funciona no iOS (apenas desktop)
- `screen_retriever` - ⚠️ Verificar suporte iOS

### 📱 Outros
- `wakelock_plus` - ✅ Funciona no iOS
- `screen_brightness` - ✅ Funciona no iOS
- `device_info_plus` - ✅ Funciona no iOS
- `flutter_stripe` - ✅ Funciona no iOS

---

## 🔧 Próximos Passos

### 1️⃣ Gerar os ícones do app
```bash
flutter pub run flutter_launcher_icons
```

### 2️⃣ Instalar os CocoaPods (necessário no macOS)
```bash
cd ios
pod install
cd ..
```

### 3️⃣ Verificar e ajustar código condicional
Você precisará adicionar condicionais no código para usar diferentes players em diferentes plataformas:

```dart
import 'dart:io' show Platform;

// No código do player:
if (Platform.isIOS) {
  // Usar video_player nativo
} else if (Platform.isAndroid) {
  // Usar media_kit_libs_android_video
} else if (Platform.isWindows) {
  // Usar media_kit_libs_windows_video
}
```

### 4️⃣ Testar no simulador iOS (requer macOS)
```bash
flutter run -d ios
```

### 5️⃣ Build para release (requer macOS + Xcode)
```bash
flutter build ios --release
```

---

## 🚨 Limitações Importantes

### ❌ Você está no Windows
- **Não é possível compilar para iOS no Windows**
- Você precisará de:
  - Um Mac com Xcode instalado, OU
  - Serviço de CI/CD como Codemagic, Bitrise, ou GitHub Actions

### 🔄 Alternativa: Usar CI/CD
Você pode configurar GitHub Actions para compilar o iOS automaticamente:
1. Fazer push do código para GitHub
2. Configurar workflow com macOS runner
3. Build automático do iOS

---

## 📝 Arquivo de exemplo para CI (GitHub Actions)

Criar arquivo `.github/workflows/build-ios.yml`:

```yaml
name: Build iOS

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.5.0'
    - run: flutter pub get
    - run: flutter build ios --release --no-codesign
```

---

## 🎯 Resumo

✅ **Estrutura iOS configurada com sucesso!**

⚠️ **Mas você precisará:**
1. Ajustar o código para usar bibliotecas compatíveis com iOS
2. Ter acesso a um Mac para compilar (ou usar CI/CD)
3. Ter conta Apple Developer para publicar na App Store ($99/ano)

---

## 📚 Recursos Úteis

- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos/mobile-ios)
- [CocoaPods](https://cocoapods.org/)
- [Xcode](https://developer.apple.com/xcode/)
- [Codemagic CI/CD](https://codemagic.io/)

