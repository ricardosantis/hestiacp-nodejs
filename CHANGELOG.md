# Changelog

## 1.0.0 (2026-06-27)

### Added
- QuickInstall App for Node.js in HestiaCP web interface
- Nginx proxy templates (NodeJS.tpl/NodeJS.stpl) with HTTP and HTTPS support
- NodeJS.sh post-apply script for automatic PM2 restart
- v-add-pm2-app CLI command for PM2 management
- NVM system-wide installation (/opt/nvm)
- PM2 global installation with systemd startup
- Automatic .env, .nvmrc, and ecosystem.config.js generation
- Auto-install of npm dependencies
- App logs directory with PM2 output
- Support for multiple Node.js apps (one per port)
- Template survival during HestiaCP upgrades (registered in install source dirs)

### Credits
- QuickInstall App approach inspired by [JLFdzDev/hestiacp-nodejs](https://github.com/JLFdzDev/hestiacp-nodejs)
- Nginx templates and PM2 management inspired by [logico/vestacp-nodejs](https://github.com/logico/vestacp-nodejs)
