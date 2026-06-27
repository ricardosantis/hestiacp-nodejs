#!/bin/bash
#=========================================================================#
# HestiaCP Node.js Hybrid Installer                                       #
# Integrates Node.js QuickInstall App + Nginx Proxy Templates + PM2       #
#=========================================================================#

BLUE="\e[34m"
GREEN="\e[32m"
CYAN="\e[36m"
ENDCOLOR="\e[0m"

echo -e "${GREEN}"
echo " ╔══════════════════════════════════════════════════╗"
echo " ║         HestiaCP Node.js Hybrid Installer        ║"
echo " ╚══════════════════════════════════════════════════╝"
echo -e "${ENDCOLOR}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

# Check HestiaCP installation
if [ ! -d "/usr/local/hestia" ]; then
	echo "HestiaCP not found. Aborting."
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

#-------------------------------------------------------------------------
# 1. Install PM2 globally if not present
#-------------------------------------------------------------------------
echo -e "${BLUE}[1/6]${ENDCOLOR} Checking PM2..."
if ! command -v pm2 &>/dev/null; then
	echo "  -> Installing PM2 globally..."
	npm install -g pm2
	pm2 startup systemd -u root --hp /root
else
	echo "  -> PM2 already installed ($(pm2 --version))"
fi

#-------------------------------------------------------------------------
# 2. Copy QuickInstall App
#-------------------------------------------------------------------------
echo -e "${BLUE}[2/6]${ENDCOLOR} Installing Node.js QuickInstall App..."
cp -r "$SCRIPT_DIR/src/quickinstall-app/NodeJs" /usr/local/hestia/web/src/app/WebApp/Installers/

chmod -R 644 /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs/
chmod 755 /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs
chmod 755 /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs/NodeJsUtils
chmod 755 /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs/templates
chmod 755 /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs/templates/nginx
chmod 755 /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs/templates/web
chmod -R 755 /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs/sample-app
find /usr/local/hestia/web/src/app/WebApp/Installers/NodeJs/sample-app -type f -exec chmod 644 {} \;
echo "  -> QuickInstall App installed ✅"

#-------------------------------------------------------------------------
# 3. Copy Nginx Proxy Templates
#-------------------------------------------------------------------------
echo -e "${BLUE}[3/6]${ENDCOLOR} Installing Nginx Proxy Templates..."
cp "$SCRIPT_DIR/src/templates/NodeJS.tpl" /usr/local/hestia/data/templates/web/nginx/
cp "$SCRIPT_DIR/src/templates/NodeJS.stpl" /usr/local/hestia/data/templates/web/nginx/
cp "$SCRIPT_DIR/src/templates/NodeJS.sh" /usr/local/hestia/data/templates/web/nginx/
chmod 644 /usr/local/hestia/data/templates/web/nginx/NodeJS.tpl
chmod 644 /usr/local/hestia/data/templates/web/nginx/NodeJS.stpl
chmod 755 /usr/local/hestia/data/templates/web/nginx/NodeJS.sh

# Also copy to install source dirs to survive HestiaCP upgrades
if [ -d "/usr/local/hestia/install/deb/templates/web/nginx" ]; then
	cp "$SCRIPT_DIR/src/templates/NodeJS."* /usr/local/hestia/install/deb/templates/web/nginx/
fi
if [ -d "/usr/local/hestia/install/rpm/templates/web/nginx" ]; then
	cp "$SCRIPT_DIR/src/templates/NodeJS."* /usr/local/hestia/install/rpm/templates/web/nginx/
fi
echo "  -> Nginx Templates installed ✅"

#-------------------------------------------------------------------------
# 4. Install v-add-pm2-app CLI tool
#-------------------------------------------------------------------------
echo -e "${BLUE}[4/6]${ENDCOLOR} Installing v-add-pm2-app..."
cp "$SCRIPT_DIR/src/bin/v-add-pm2-app" /usr/local/hestia/bin/
chmod 755 /usr/local/hestia/bin/v-add-pm2-app
echo "  -> v-add-pm2-app installed ✅"

#-------------------------------------------------------------------------
# 5. Set up NVM system-wide (if not already installed)
#-------------------------------------------------------------------------
echo -e "${BLUE}[5/6]${ENDCOLOR} Checking NVM..."
if [ ! -f /opt/nvm/nvm.sh ]; then
	echo "  -> Installing NVM system-wide in /opt/nvm..."
	wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

	# Move to /opt/nvm for system-wide access
	mv ~/.nvm /opt/nvm 2>/dev/null || true
	chmod -R 777 /opt/nvm

	# Add to /etc/profile for all users
	if ! grep -q "NVM_DIR.*/opt/nvm" /etc/profile; then
		cat >> /etc/profile <<'NVM_EOS'

# Node.js NVM (system-wide)
export NVM_DIR="/opt/nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
	\. "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
	\. "$NVM_DIR/bash_completion"
fi
NVM_EOS
	fi

	echo "  -> NVM installed in /opt/nvm ✅"
else
	echo "  -> NVM already installed in /opt/nvm ✅"
fi

#-------------------------------------------------------------------------
# 6. Set PM2 to start on boot for all existing users
#-------------------------------------------------------------------------
echo -e "${BLUE}[6/6]${ENDCOLOR} Configuring PM2 startup..."
if command -v pm2 &>/dev/null; then
	# Enable PM2 startup for root
	pm2 startup systemd -u root --hp /root 2>/dev/null
	pm2 save 2>/dev/null

	# Get list of HestiaCP users and enable PM2 for them
	for user_home in /home/*; do
		if [ -d "$user_home" ]; then
			username=$(basename "$user_home")
			if id "$username" &>/dev/null; then
				# Pre-create .pm2 so PM2 can write (home is root-owned, read-only for user)
				mkdir -p "$user_home/.pm2"
				chown "$username:$username" "$user_home/.pm2"
				chmod 700 "$user_home/.pm2"

				# Generate PM2 startup (run as root, --hp sets PM2_HOME)
				pm2 startup systemd -u "$username" --hp "$user_home" 2>/dev/null
			fi
		fi
	done
	echo "  -> PM2 startup configured ✅"
fi

#-------------------------------------------------------------------------
# Done
#-------------------------------------------------------------------------
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${ENDCOLOR}"
echo -e "${GREEN}║           Installation Complete!                ║${ENDCOLOR}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${ENDCOLOR}"
echo ""
echo "Next steps:"
echo "  1. Create a web domain in HestiaCP"
echo "  2. Go to Edit Web -> Quick Install App -> NodeJs"
echo "  3. Select Node version, start script, and port"
echo "  4. Install"
echo "  5. Upload your app to: /home/<user>/web/<domain>/nodeapp/"
echo "  6. The app will auto-start via PM2"
echo ""
