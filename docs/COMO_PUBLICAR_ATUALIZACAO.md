# Como publicar uma atualização (para o utilizador ver na app)

Este guia explica como subir uma nova versão para que os utilizadores vejam o diálogo de atualização ao abrir a app.

---

## 1. Subir a versão no projeto

Edita o **`pubspec.yaml`** na raiz do projeto:

```yaml
version: 1.4.32+152   # ← altera para a nova versão
```

- O **primeiro número** (ex: `1.4.33`) é a versão que aparece ao utilizador e que a app compara com o `version.json`.
- O **número após o `+`** (ex: `153`) é o build number (pode incrementar em cada release).

Exemplo para a próxima atualização:

```yaml
version: 1.4.33+153
```

Guarda o ficheiro, faz commit e push (se quiseres que o release seja criado por tag).

---

## 2. Criar o build e o release no GitHub

A app usa o ficheiro **`version.json`** para saber se há atualização. Esse ficheiro está configurado para ser lido deste URL:

- **URL do version.json:**  
  `https://raw.githubusercontent.com/rafadeveloper92-lang/luminoriapro/main/docs/version.json`

Ou seja: o **repositório que a app consulta** é o **luminoriapro** (pasta `docs/`, ficheiro `version.json`). Os instaladores podem estar noutro repo (por exemplo neste FlutterIPTV), mas o **version.json tem de estar no repo que está no código** (luminoriapro) **ou** tens de alterar esse URL no código para apontar para o repo onde fazes os releases.

Tens duas formas de gerar os instaladores:

### Opção A – Release por tag (recomendado)

1. No repositório onde corre o workflow (ex: FlutterIPTV ou luminoriapro):
   - Cria uma **tag** com o número da versão, por exemplo: **`v1.4.33`**
   - Faz push da tag:
     ```bash
     git tag v1.4.33
     git push origin v1.4.33
     ```
2. O workflow **Build and Release** (`.github/workflows/build-release.yml`) é acionado pela tag `v*.*.*`.
3. Quando terminar, em **Releases** aparece a release `v1.4.33` com:
   - `flutteriptv-Windows-x64-Setup.exe`
   - `flutteriptv-Android-arm64.apk`
   - (e iOS se configurado)

### Opção B – Release manual (workflow_dispatch)

1. No GitHub: **Actions** → workflow **Build and Release** → **Run workflow**.
2. No campo **Version number** coloca, por exemplo: **`1.4.33`** (sem o `v`).
3. Corre o workflow. No fim, a release é criada com esse número (a tag pode ser criada pelo workflow conforme estiver configurado).

---

## 3. URLs de download do release

Cada ficheiro no release tem um URL direto no formato:

```
https://github.com/OWNER/REPO/releases/download/TAG/NOME_DO_FICHEIRO
```

Exemplo para o repositório **FlutterIPTV** (troca pelo teu owner/repo e tag):

- Windows:  
  `https://github.com/OWNER/FlutterIPTV/releases/download/v1.4.33/flutteriptv-Windows-x64-Setup.exe`
- Android (arm64):  
  `https://github.com/OWNER/FlutterIPTV/releases/download/v1.4.33/flutteriptv-Android-arm64.apk`

Se os releases forem no **luminoriapro**, usa:

- `https://github.com/rafadeveloper92-lang/luminoriapro/releases/download/v1.4.33/...`

---

## 4. Criar ou atualizar o `version.json`

A app lê o **version.json** do repositório **luminoriapro** (pasta `docs/`). Esse ficheiro tem de existir nesse repo e ser atualizado em cada nova versão.

Caminho no repo: **`docs/version.json`**

Estrutura esperada (a app usa `version`, `build`, `releaseDate`, `assets`, `changelog`):

```json
{
  "version": "1.4.33",
  "build": 153,
  "releaseDate": "2025-02-10T12:00:00.000Z",
  "minVersion": "1.0.0",
  "assets": {
    "windows": "https://github.com/OWNER/REPO/releases/download/v1.4.33/flutteriptv-Windows-x64-Setup.exe",
    "android_mobile": {
      "arm64-v8a": "https://github.com/OWNER/REPO/releases/download/v1.4.33/flutteriptv-Android-arm64.apk",
      "armeabi-v7a": "https://github.com/OWNER/REPO/releases/download/v1.4.33/flutteriptv-Android-arm64.apk",
      "universal": "https://github.com/OWNER/REPO/releases/download/v1.4.33/flutteriptv-Android-arm64.apk"
    },
    "android_tv": {
      "arm64-v8a": "https://github.com/OWNER/REPO/releases/download/v1.4.33/flutteriptv-Android-arm64.apk",
      "armeabi-v7a": "https://github.com/OWNER/REPO/releases/download/v1.4.33/flutteriptv-Android-arm64.apk",
      "universal": "https://github.com/OWNER/REPO/releases/download/v1.4.33/flutteriptv-Android-arm64.apk"
    }
  },
  "changelog": {
    "pt": "• Verificação de atualização ao abrir a app\n• Melhorias gerais",
    "en": "• Update check on app open\n• General improvements",
    "zh": "• 启动时检查更新\n• 一般改进"
  }
}
```

Notas:

- **version**: tem de ser **maior** que a versão atual no `pubspec.yaml` dos utilizadores (ex: `1.4.33` > `1.4.32`).
- **build**: normalmente igual ao número após o `+` no pubspec (ex: `153`).
- **releaseDate**: data da release em ISO 8601.
- **assets.windows**: URL direto do `.exe` do Windows.
- **assets.android_mobile** / **assets.android_tv**: URLs por arquitetura; se só tiveres um APK (ex: arm64), podes usar o mesmo URL em `arm64-v8a`, `armeabi-v7a` e `universal`.
- **changelog**: texto mostrado no diálogo de atualização; a app usa `pt`, `en` ou `zh` conforme o idioma.

Onde atualizar:

- Se o **version.json** está no repo **luminoriapro**: faz commit e push de `docs/version.json` nesse repo (com os URLs do repo onde realmente publicas os instaladores, se for outro).
- Se quiseres que tudo fique no **mesmo** repo (por exemplo FlutterIPTV):  
  - Coloca `docs/version.json` nesse repo (neste projeto já existe um exemplo em **`docs/version.json`**).  
  - Altera no código o URL em `lib/core/services/update_service.dart` (constantes `_versionJsonUrl` e `_githubReleasesUrl`) para apontar para esse repo.

**Nota:** O workflow deste projeto (FlutterIPTV-main) gera apenas um APK por build (`flutteriptv-Android-arm64.apk`). No `version.json` podes usar o mesmo URL em `arm64-v8a`, `armeabi-v7a` e `universal` se não tiveres builds separados por arquitetura.

---

## 5. Resumo do fluxo

1. **Subir versão** no `pubspec.yaml` (ex: `1.4.33+153`).
2. **Criar release** (tag `v1.4.33` ou workflow manual) no repo onde está o workflow.
3. **Copiar os URLs** dos ficheiros da release (Windows .exe, Android .apk).
4. **Criar/atualizar `docs/version.json`** no repositório que o `UpdateService` usa (luminoriapro ou o que configurares), com essa versão e esses URLs.
5. Os utilizadores, ao abrir a app, vão ver “Verificando atualizações...” e, se a versão deles for menor, o diálogo de atualização com “Atualizar agora” / “Depois”.

---

## 6. Repositório atual no código

No ficheiro **`lib/core/services/update_service.dart`** está:

- **version.json:**  
  `https://raw.githubusercontent.com/rafadeveloper92-lang/luminoriapro/main/docs/version.json`
- **Página de releases (link “Ver atualizações”):**  
  `https://github.com/rafadeveloper92-lang/luminoriapro/releases`

Se publicares noutro repo (por exemplo `FlutterIPTV-main`), deves:

1. Colocar o `version.json` nesse repo (ex: em `docs/version.json`).
2. Alterar as duas constantes no `update_service.dart` para o novo owner/repo (e ramo, se for diferente de `main`).

Assim a app passa a verificar atualizações e a abrir a página de releases no repositório onde realmente publicas.
