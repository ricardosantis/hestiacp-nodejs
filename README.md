# HestiaCP Node.js Integration

> Run Node.js applications on HestiaCP with ease — QuickInstall App, PM2, NVM, and Nginx reverse proxy.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

---

## Overview

This project integrates **Node.js** support into [HestiaCP](https://hestiacp.com/) control panel. It provides:

- **QuickInstall App** — Install Node.js apps directly from the HestiaCP web interface
- **Nginx Proxy Templates** — Reverse proxy for Node.js apps with HTTP/HTTPS support
- **PM2 Process Manager** — Automatic startup, restart, and monitoring
- **NVM Support** — Per-app Node.js version management
- **CLI Tools** — `v-add-pm2-app` command for PM2 management

### How it works

```
User → Nginx (80/443) → NodeJS Proxy Template → Node.js App (port 3000)
                                                     ↓
                                                  PM2 (process management)
                                                     ↓
                                                  NVM (Node version)
```

---

## Requirements

- HestiaCP 1.8.x or later
- Root access to the server
- User must have **SSH Access = bash** (Edit User → Advanced Options)

## Installation (one-time server setup)

Run this **once** on your server. After that, everything is done through the HestiaCP web panel.

```bash
git clone https://github.com/ricardosantis/hestiacp-nodejs.git
cd hestiacp-nodejs
chmod +x install.sh
sudo ./install.sh
```

The script will:

1. Install PM2 globally
2. Install NVM system-wide (`/opt/nvm`)
3. Copy the QuickInstall App to HestiaCP
4. Install Nginx proxy templates
5. Add `v-add-pm2-app` CLI command
6. Configure PM2 startup on boot

> **Note:** You only need to run `install.sh` again if you upgrade HestiaCP and the NodeJS proxy template disappears. The templates are also saved in HestiaCP's install source directories to minimize this risk.

---

## Usage

### Via Web Interface (Recommended)

**Step 1 — Create a domain**  
Go to **WEB** → **Add Domain** and create your domain.
**Step 2 — Install NodeJs**  

Edit the domain → **Quick Install App** → Select **NodeJs**.
Fill in:
- **Node Version** — e.g. `v22.14.0`
- **Install sample app (Hello World)** — check this box to deploy a ready-to-run sample app (configured on port `3000`, entrypoint `app.js`)

Click **Install**. The installer will:
1. Create the app directory with config files (`.env`, `.nvmrc`, `ecosystem.config.js`)
2. If checked, deploy a sample app (no extra dependencies)
3. Set the proxy template to NodeJS
4. Start the app via PM2

**Step 3 — Access your app**  
Your app is immediately accessible at `http://<domain>/`.  
No SSH, no SCP, no Git required.

**Step 4 — Upload your own files** (skip if using the sample app)  
Use the **File Manager** in HestiaCP to upload your app files to:
```
/home/<user>/web/<domain>/private/nodeapp/
```
After uploading, restart via PM2:
```
runuser -l <user> -c "pm2 restart <domain>"
```

### Manual Setup

```bash
# Create app directory
v-add-fs-directory <user> /home/<user>/web/<domain>/private/nodeapp

# Upload your app files (via File Manager, SCP, or Git)

# Set proxy template to NodeJS
v-change-web-domain-proxy-tpl <user> <domain> NodeJS

# Start with PM2
v-add-pm2-app <user> <domain> ecosystem.config.js
```

### PM2 Management

```bash
# List processes
runuser -l <user> -c "pm2 list"

# View logs
runuser -l <user> -c "pm2 logs <domain>"

# Restart
runuser -l <user> -c "pm2 restart <domain>"

# Stop
runuser -l <user> -c "pm2 stop <domain>"

# Save process list (for auto-restart on reboot)
runuser -l <user> -c "pm2 save"
```

---

## File Structure

```
hestiacp-nodejs/
├── install.sh                          # Installation script
├── src/
│   ├── templates/                      # Nginx proxy templates
│   │   ├── NodeJS.tpl                  #   HTTP template
│   │   ├── NodeJS.stpl                 #   HTTPS template
│   │   └── NodeJS.sh                   #   Post-apply script
│   ├── bin/
│   │   └── v-add-pm2-app              # HestiaCP CLI for PM2
│   └── quickinstall-app/
│       └── NodeJs/                    # QuickInstall App
│           ├── NodeJsSetup.php        #   Main installer class
│           ├── nodejs.png             #   Thumbnail icon
│           ├── NodeJsUtils/
│           │   ├── NodeJsPaths.php    #   Path management
│           │   └── NodeJsUtil.php     #   Utility functions
│           └── templates/
│               ├── web/entrypoint.tpl #   ecosystem.config.js template
│               └── nginx/
│                   ├── nodejs-app.tpl #   Proxy config template
│                   └── nodejs-app-fallback.tpl  # Fallback template
```

---

## Upgrade Survival

After a HestiaCP upgrade, if the NodeJS proxy template disappears:

```bash
sudo ./install.sh
```

This reapplies all components in seconds. The templates are also registered in HestiaCP's install source directories (`/usr/local/hestia/install/deb/` and `/usr/local/hestia/install/rpm/`), so they survive `v-update-web-templates`.

---

## Troubleshooting

### App won't start
- Verify user has **SSH Access = bash**
- Check PM2 logs: `runuser -l <user> -c "pm2 logs <domain>"`
- Check app logs: `/home/<user>/web/<domain>/private/nodeapp/logs/`

### Port already in use
```bash
ss -tlnp | grep <port>
```

### Blank page
- Verify proxy template is set to **NodeJS** (Edit Web → Advanced Options → Proxy Template)

### File Manager "UNKNOWN ERROR" (Ubuntu 24.04 / Modern OpenSSH)
On Ubuntu 24.04 and modern systems, the HestiaCP File Manager might fail with "UNKNOWN ERROR" (visible in Hestia's nginx error log as a `ConnectionErrorException` from the SFTP adapter). 

This is a pre-existing HestiaCP compatibility issue with modern OpenSSH, which disables the old `ssh-rsa` signature algorithm by default (HestiaCP generates 1024-bit RSA keys for File Manager SFTP).

To resolve this on your server without modifying HestiaCP core files:

1. Open `/etc/ssh/sshd_config` and append the following line at the end:
   ```
   PubkeyAcceptedAlgorithms +ssh-rsa
   ```
2. Restart the SSH service:
   ```bash
   sudo systemctl restart ssh
   ```
3. Close the File Manager, log out of HestiaCP, log back in, and try opening the File Manager again. The key will be successfully negotiated and the File Manager will work perfectly.

### App won't restart after deploy
```bash
# Toggle proxy template to restart
v-change-web-domain-proxy-tpl <user> <domain> default
v-change-web-domain-proxy-tpl <user> <domain> NodeJS
```

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).

---

## Credits

This project combines ideas from:
- [JLFdzDev/hestiacp-nodejs](https://github.com/JLFdzDev/hestiacp-nodejs) — QuickInstall App integration
- [logico/vestacp-nodejs](https://github.com/logico/vestacp-nodejs) — Nginx proxy templates and PM2 management
