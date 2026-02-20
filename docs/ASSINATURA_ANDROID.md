# Assinatura Android – Keystore própria (sem Play Store)

Como você pegou o app no GitHub e está modificando, **não tem a keystore original**. O erro *"O pacote entra em conflito com um pacote existente"* acontece quando o APK novo é assinado com **outra chave** que a versão já instalada no telemóvel.

A solução é criar **uma keystore só sua** e usá-la em **todos** os builds de release. Assim, as atualizações (incluindo “Atualizar agora” dentro do app) passam a instalar sem conflito.

---

## 1. Criar a keystore (só uma vez)

No terminal, na pasta do projeto (ou noutra pasta onde queiras guardar a keystore):

**Windows (PowerShell):**
```powershell
cd android
keytool -genkey -v -keystore app\luminora-release.keystore -alias luminora -keyalg RSA -keysize 2048 -validity 10000
```

**Linux / Mac:**
```bash
cd android
keytool -genkey -v -keystore app/luminora-release.keystore -alias luminora -keyalg RSA -keysize 2048 -validity 10000
```

O `keytool` vem com o Java (JDK). O comando vai pedir:
- senha da keystore (guarda bem),
- nome, organização, etc. (podes preencher como quiseres),
- senha da key (pode ser a mesma da keystore).

Guarda a **keystore** e as **senhas** em sítio seguro. Quem perder estes ficheiros não consegue publicar atualizações para a mesma app.

---

## 2. Criar o ficheiro `key.properties`

Na pasta **`android`** (ao lado de `build.gradle.kts`), cria um ficheiro chamado **`key.properties`** com este conteúdo (ajusta os valores):

```properties
storePassword=SUA_SENHA_DA_KEYSTORE
keyPassword=SUA_SENHA_DA_KEY
keyAlias=luminora
storeFile=app/luminora-release.keystore
```

- `storePassword`: senha da keystore  
- `keyPassword`: senha da key (se for a mesma, repete)  
- `keyAlias`: o alias que usaste no `keytool` (ex.: `luminora`)  
- `storeFile`: caminho da keystore **em relação à pasta `android/app`**. Se a keystore está em `android/app/luminora-release.keystore`, usa só `luminora-release.keystore`.

O ficheiro `key.properties` **não** deve ser enviado para o Git (já está no `.gitignore`). A keystore também não (`.keystore` está ignorada).

---

## 3. Resolver o conflito na instalação (uma vez por dispositivo)

Como a app que tens instalada foi assinada com **outra** chave (do autor original ou debug):

1. **Desinstala** a app “Luminora” do telemóvel.
2. **Instala** o novo APK que construíres com a **tua** keystore (a que criaste em cima).

A partir daí, todas as versões que construíres com essa mesma keystore podem ser instaladas por cima (incluindo “Atualizar agora” dentro do app), sem erro de conflito.

---

## 4. Build de release (sempre com a mesma keystore)

```bash
flutter build apk --release
```

Ou, por arquitectura:

```bash
flutter build apk --release --split-per-abi
```

Os APK gerados em `build/app/outputs/` estarão assinados com a tua keystore. Usa **sempre** esta keystore e este `key.properties` para não voltar a ter conflito.

---

## Resumo

| Situação | O que fazer |
|----------|-------------|
| Primeira vez / “conflito de pacote” | Criar keystore + `key.properties`, desinstalar a app no telemóvel, instalar o novo APK. |
| Próximas atualizações | Manter a mesma keystore e o mesmo `key.properties` em todos os builds de release. |
| Perder a keystore ou as senhas | Não há forma de “recuperar”. Novas instalações terão de ser feitas desinstalando a app antiga (e os utilizadores perdem dados locais da app). |

Se quiseres usar outro nome ou outra pasta para a keystore, basta ajustar `storeFile` no `key.properties` e garantir que o caminho é relativo à pasta `android`.
