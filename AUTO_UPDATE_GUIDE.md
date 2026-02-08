# 📱 Sistema de Atualização Automática - Guia

## 🔄 Como Funciona

O app verifica automaticamente por atualizações:
- ⏰ A cada **24 horas** automaticamente
- 🔘 Ou quando o usuário clica em **"Verificar Atualizações"** nas configurações

### Fluxo:
1. App acessa: `https://raw.githubusercontent.com/rafadeveloper92-lang/luminoriapro/main/docs/version.json`
2. Compara a versão atual com a versão no arquivo
3. Se houver nova versão, mostra notificação
4. Usuário pode baixar e instalar automaticamente

---

## 📝 Como Atualizar Quando Fizer Nova Release

### **Passo 1: Editar `version.json`**

Após criar uma nova release (ex: v1.4.34), atualize o arquivo `docs/version.json`:

```json
{
  "version": "1.4.34",  // ← Nova versão
  "build": 154,          // ← Incrementar
  "releaseDate": "2026-02-15",  // ← Data
  "assets": {
    "windows": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-Windows-x64-Setup.exe",
    "android_mobile": {
      "arm64-v8a": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-Android-Mobile-arm64-v8a.apk",
      "armeabi-v7a": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-Android-Mobile-armeabi-v7a.apk",
      "x86_64": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-Android-Mobile-x86_64.apk"
    },
    "android_tv": {
      "arm64-v8a": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-AndroidTV-arm64-v8a.apk",
      "armeabi-v7a": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-AndroidTV-armeabi-v7a.apk",
      "x86_64": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-AndroidTV-x86_64.apk"
    },
    "ios": {
      "universal": "https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.34/flutteriptv-iOS-unsigned.ipa"
    }
  },
  "changelog": {
    "zh": "- Suas mudanças em chinês",
    "en": "- Your changes in English"
  },
  "minVersion": "1.0.0"
}
```

### **Passo 2: Commitar a Mudança**

```bash
git add docs/version.json
git commit -m "Atualizar version.json para v1.4.34"
git push origin main
```

### **Passo 3: Criar Release**

```bash
git tag v1.4.34
git push origin v1.4.34
```

**PRONTO!** Em 24h ou quando usuários clicarem em "Verificar Atualizações", eles verão a nova versão!

---

## 🎯 Processo Completo para Nova Versão

### **Ordem Correta:**

1. **Fazer mudanças no código**
2. **Atualizar `version.json`** com nova versão
3. **Commit e push**
4. **Criar tag** (inicia build GitHub Actions)
5. **Aguardar build** (~25 min)
6. **Release criado automaticamente** com arquivos
7. **Usuários serão notificados** automaticamente!

---

## 📂 Estrutura do `version.json`

```json
{
  "version": "X.Y.Z",           // Versão semântica
  "build": NUM,                 // Número do build
  "releaseDate": "YYYY-MM-DD",  // Data
  "assets": {                   // Links de download
    "windows": "URL_EXE",
    "android_mobile": {
      "arm64-v8a": "URL_APK",
      "armeabi-v7a": "URL_APK",
      "x86_64": "URL_APK"
    },
    "android_tv": {
      "arm64-v8a": "URL_APK",
      "armeabi-v7a": "URL_APK",
      "x86_64": "URL_APK"
    },
    "ios": {
      "universal": "URL_IPA"
    }
  },
  "changelog": {
    "zh": "Mudanças em chinês",
    "en": "Changes in English"
  },
  "minVersion": "1.0.0"         // Versão mínima suportada
}
```

---

## ⚠️ IMPORTANTE

### **URLs Devem Seguir o Padrão:**
```
https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/vX.Y.Z/arquivo.ext
```

### **Sempre:**
- ✅ Atualizar `version.json` ANTES de criar a tag
- ✅ Usar mesma versão no `version.json` e na tag
- ✅ Testar o arquivo JSON em: https://jsonlint.com/
- ✅ Commitar o `version.json` junto com as mudanças

---

## 🧪 Testar Localmente

Para testar se o sistema funciona:

1. Instale uma versão antiga do app
2. Atualize o `version.json` no GitHub com versão maior
3. Abra o app → Configurações → Verificar Atualizações
4. Deve mostrar que há atualização disponível

---

## 🔧 Troubleshooting

### **App não detecta atualização:**
- Verifique se o `version.json` está acessível
- Teste a URL no navegador
- Verifique se a versão no JSON é maior que a instalada

### **Download falha:**
- Verifique se os links dos assets estão corretos
- Confirme que a release foi criada com sucesso
- Teste os links de download no navegador

---

## 💡 Dica

Crie um script para atualizar automaticamente:

```bash
# update-version.sh
#!/bin/bash
NEW_VERSION=$1
sed -i "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" docs/version.json
sed -i "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v$NEW_VERSION/g" docs/version.json
git add docs/version.json
git commit -m "Update to v$NEW_VERSION"
git push origin main
git tag v$NEW_VERSION
git push origin v$NEW_VERSION
```

Uso: `./update-version.sh 1.4.34`

