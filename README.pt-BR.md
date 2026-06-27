# HestiaCP — Integração Node.js

> Execute aplicações Node.js no HestiaCP com facilidade — QuickInstall App, PM2, NVM e proxy reverso Nginx.

[![License: GPL v3](https://img.shields.io/badge/Licen%C3%A7a-GPLv3-blue.svg)](LICENSE)

---

## Visão Geral

Este projeto integra suporte a **Node.js** no painel de controle [HestiaCP](https://hestiacp.com/). Ele fornece:

- **QuickInstall App** — Instale apps Node.js diretamente pela interface web do HestiaCP
- **Templates de Proxy Nginx** — Proxy reverso para apps Node.js com suporte HTTP/HTTPS
- **PM2** — Gerenciador de processos com inicialização automática e monitoramento
- **NVM** — Gerenciamento de versão do Node.js por aplicação
- **CLI** — Comando `v-add-pm2-app` para gerenciamento via terminal

### Funcionamento

```
Usuário → Nginx (80/443) → Template Proxy NodeJS → App Node.js (porta 3000)
                                                       ↓
                                                    PM2 (gerenciamento)
                                                       ↓
                                                    NVM (versão Node)
```

---

## Requisitos

- HestiaCP 1.8.x ou superior
- Acesso root ao servidor
- Usuário deve ter **SSH Access = bash** (Editar Usuário → Advanced Options)

## Instalação (única no servidor)

Execute **uma única vez** no servidor. Depois disso, tudo é feito pelo painel web do HestiaCP.

```bash
git clone https://github.com/ricardosantis/hestiacp-nodejs.git
cd hestiacp-nodejs
chmod +x install.sh
sudo ./install.sh
```

O script irá:

1. Instalar o PM2 globalmente
2. Instalar o NVM em `/opt/nvm`
3. Copiar o QuickInstall App para o HestiaCP
4. Instalar os templates de proxy Nginx
5. Adicionar o comando `v-add-pm2-app`
6. Configurar inicialização automática do PM2

> **Nota:** Só precisa rodar `install.sh` novamente se você atualizar o HestiaCP e o template NodeJS desaparecer. Os templates também foram salvos nos diretórios de instalação do HestiaCP para minimizar esse risco.

---

## Como Usar

### Pela Interface Web (Recomendado)

**Passo 1 — Crie um domínio**  
Vá em **WEB** → **Add Domain** e crie seu domínio.
**Passo 2 — Instale o NodeJs**  

Edite o domínio → **Quick Install App** → Selecione **NodeJs**.
Preencha:
- **Node Version** — ex: `v22.14.0`
- **Install sample app (Hello World)** — marque para instalar uma app de exemplo pronta (configurada na porta `3000`, entrypoint `app.js`)

Clique em **Install**. O instalador irá:
1. Criar o diretório da app com arquivos de configuração (`.env`, `.nvmrc`, `ecosystem.config.js`)
2. Se marcado, instalar uma app de exemplo (sem dependências externas)
3. Aplicar o template de proxy NodeJS
4. Iniciar a app via PM2

**Passo 3 — Acesse sua app**  
Sua app está imediatamente acessível em `http://<dominio>/`.  
Sem SSH, sem SCP, sem Git necessários.

**Passo 4 — Envie seus próprios arquivos** (pule se usou a sample app)  
Use o **File Manager** do HestiaCP para enviar sua app para:
```
/home/<usuario>/web/<dominio>/private/nodeapp/
```
Após enviar, reinicie via PM2:
```
runuser -l <usuario> -c "pm2 restart <dominio>"
```

### Configuração Manual

```bash
# Criar diretório da app
v-add-fs-directory <usuario> /home/<usuario>/web/<dominio>/private/nodeapp

# Enviar arquivos (File Manager, SCP ou Git)

# Aplicar template de proxy
v-change-web-domain-proxy-tpl <usuario> <dominio> NodeJS

# Iniciar com PM2
v-add-pm2-app <usuario> <dominio> ecosystem.config.js
```

### Gerenciamento PM2

```bash
# Listar processos
runuser -l <usuario> -c "pm2 list"

# Ver logs
runuser -l <usuario> -c "pm2 logs <dominio>"

# Reiniciar
runuser -l <usuario> -c "pm2 restart <dominio>"

# Parar
runuser -l <usuario> -c "pm2 stop <dominio>"

# Salvar lista (restart automático após reboot)
runuser -l <usuario> -c "pm2 save"
```

---

## Estrutura de Arquivos

```
hestiacp-nodejs/
├── install.sh                          # Script de instalação
├── src/
│   ├── templates/                      # Templates de proxy Nginx
│   │   ├── NodeJS.tpl                  #   Template HTTP
│   │   ├── NodeJS.stpl                 #   Template HTTPS
│   │   └── NodeJS.sh                   #   Script pós-aplicação
│   ├── bin/
│   │   └── v-add-pm2-app              # CLI do HestiaCP para PM2
│   └── quickinstall-app/
│       └── NodeJs/                    # QuickInstall App
│           ├── NodeJsSetup.php        #   Classe principal do instalador
│           ├── nodejs.png             #   Ícone do instalador
│           ├── NodeJsUtils/
│           │   ├── NodeJsPaths.php    #   Gerenciamento de caminhos
│           │   └── NodeJsUtil.php     #   Funções utilitárias
│           └── templates/
│               ├── web/entrypoint.tpl #   Template ecosystem.config.js
│               └── nginx/
│                   ├── nodejs-app.tpl #   Template configuração proxy
│                   └── nodejs-app-fallback.tpl  # Template fallback
```

---

## Sobrevivência a Upgrades

Se após uma atualização do HestiaCP o template NodeJS desaparecer:

```bash
sudo ./install.sh
```

Isso reaplica todos os componentes em segundos. Os templates também foram registrados nos diretórios de instalação do HestiaCP (`/usr/local/hestia/install/deb/` e `/usr/local/hestia/install/rpm/`), garantindo que sobrevivam ao `v-update-web-templates`.

---

## Solução de Problemas

### App não inicia
- Verifique se o usuário tem **SSH Access = bash**
- Verifique logs do PM2: `runuser -l <usuario> -c "pm2 logs <dominio>"`
- Verifique logs da app: `/home/<usuario>/web/<dominio>/private/nodeapp/logs/`

### Porta já em uso
```bash
ss -tlnp | grep <porta>
```

### Página em branco
- Verifique se o template de proxy está como **NodeJS** (Editar Web → Advanced Options → Proxy Template)

### Gerenciador de Arquivos "UNKNOWN ERROR" (Ubuntu 24.04 / OpenSSH Moderno)
No Ubuntu 24.04 e sistemas modernos, o Gerenciador de Arquivos do HestiaCP pode falhar com "UNKNOWN ERROR" (visível no log do HestiaCP como `ConnectionErrorException` do SFTP).

Este é um problema de compatibilidade nativo do HestiaCP com o OpenSSH moderno, que por padrão desabilita chaves RSA antigas (o HestiaCP gera chaves RSA de 1024 bits para a conexão do Gerenciador).

Para resolver isso no seu servidor sem modificar nenhum arquivo original do HestiaCP:

1. Abra o arquivo `/etc/ssh/sshd_config` e adicione a seguinte linha no final do arquivo:
   ```
   PubkeyAcceptedAlgorithms +ssh-rsa
   ```
2. Reinicie o serviço de SSH:
   ```bash
   sudo systemctl restart ssh
   ```
3. Feche o Gerenciador de Arquivos, faça logout do painel, logue novamente e tente abrir o Gerenciador. O SSH vai aceitar a chave e funcionará perfeitamente.

### App não reinicia após deploy
```bash
# Alternar template de proxy para forçar restart
v-change-web-domain-proxy-tpl <usuario> <dominio> default
v-change-web-domain-proxy-tpl <usuario> <dominio> NodeJS
```

---

## Licença

GNU General Public License v3.0 — veja [LICENSE](LICENSE).

---

## Créditos

Este projeto combina ideias de:
- [JLFdzDev/hestiacp-nodejs](https://github.com/JLFdzDev/hestiacp-nodejs) — Integração QuickInstall App
- [logico/vestacp-nodejs](https://github.com/logico/vestacp-nodejs) — Templates de proxy Nginx e gerenciamento PM2
