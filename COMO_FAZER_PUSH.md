# 🚀 Como Fazer o Push para o GitHub

## ⚠️ Problema Atual

Você está com um proxy ou VPN que está bloqueando a conexão com o GitHub através do Git.

Erro: `Failed to connect to github.com port 443 via 127.0.0.1`

---

## ✅ SOLUÇÃO RÁPIDA (Recomendada)

### Passo 1: Executar o Script Automático

1. Abra o arquivo: `push-to-github.bat` (está na raiz do projeto)
2. Execute ele (duplo clique)
3. Siga as instruções na tela

**OU**

Abra o PowerShell/CMD **como Administrador** e execute:
```bash
cd C:\Users\rafaa\lotus\FlutterIPTV-main
.\push-to-github.bat
```

---

## 🔐 Se Pedir Usuário e Senha

O GitHub não aceita mais senha normal. Você precisa usar um **Personal Access Token**:

### Como Gerar o Token:

1. Acesse: https://github.com/settings/tokens
2. Clique em "Generate new token" → "Generate new token (classic)"
3. Dê um nome: `Luminoria Upload`
4. Marque: `✓ repo` (Full control of private repositories)
5. Clique em "Generate token"
6. **COPIE O TOKEN** (só aparece uma vez!)

### Como Usar:

Quando pedir:
- **Username:** `rafadeveloper92-lang`
- **Password:** Cole o token que você copiou

---

## 🛡️ Se Você Usa VPN ou Proxy

### Opção 1: Desativar Temporariamente

1. Desative sua VPN/Proxy
2. Execute o script `push-to-github.bat`
3. Reative depois

### Opção 2: Configurar Proxy no Git

Se você sabe as configurações do seu proxy:

```bash
git config --global http.proxy http://proxy.server.com:port
git config --global https.proxy https://proxy.server.com:port
```

---

## 📝 COMANDOS MANUAIS (se preferir)

Se quiser fazer manualmente sem o script:

```bash
# 1. Ir para a pasta
cd C:\Users\rafaa\lotus\FlutterIPTV-main

# 2. Verificar se está tudo configurado
git status

# 3. Fazer o push
git push -u origin main
```

---

## ✅ DEPOIS DO PUSH

Quando der certo, você verá:
```
Enumerating objects: ...
Counting objects: 100% (325/325), done.
...
To https://github.com/rafadeveloper92-lang/Luminoriadefinition.git
 * [new branch]      main -> main
```

Então acesse: https://github.com/rafadeveloper92-lang/Luminoriadefinition

E você verá todo o código lá! 🎉

---

## 🏷️ Criar a Release com iOS

Depois do push funcionar, execute:

```bash
# Criar e enviar a tag de versão
git tag v1.4.33
git push origin v1.4.33
```

E o GitHub Actions vai compilar automaticamente:
- Windows
- Android Mobile
- Android TV  
- **iOS** 🍎

Em ~25 minutos você terá todos os arquivos prontos!

---

## 🆘 Ainda Não Funciona?

Se ainda estiver com problema, me avise e vamos tentar:
1. Configurar SSH ao invés de HTTPS
2. Usar o GitHub Desktop
3. Fazer upload manual via navegador

---

**Status Atual:**
- ✅ Código commitado localmente
- ✅ Repositório remoto criado
- ⏳ Aguardando push (problema de conexão)

Tudo pronto, só precisa resolver a conexão com o GitHub!

