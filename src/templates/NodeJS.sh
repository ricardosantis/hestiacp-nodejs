#!/bin/bash
# info: NodeJS proxy template helper
# Called when NodeJS proxy template is applied to a domain
# args: user domain ip home docroot

user=$1
domain=$2
ip=$3
home=$4
docroot=$5

nodeapp_dir="$home/$user/web/$domain/private/nodeapp"

if [ ! -d "$nodeapp_dir" ]; then
	exit 0
fi

# Load NVM
if [ -f /opt/nvm/nvm.sh ]; then
	export NVM_DIR="/opt/nvm"
	source "$NVM_DIR/nvm.sh"
fi

# Install deps if needed (as user, not root)
if [ -f "$nodeapp_dir/package.json" ] && [ ! -d "$nodeapp_dir/node_modules" ]; then
	runuser -l "$user" -c "export NVM_DIR=/opt/nvm && source /opt/nvm/nvm.sh && cd \"$nodeapp_dir\" && npm install"
fi

# Restart PM2
if [ -f "$nodeapp_dir/ecosystem.config.js" ]; then
	runuser -l "$user" -c "pm2 restart \"$domain\" 2>/dev/null || pm2 start \"$nodeapp_dir/ecosystem.config.js\" --name \"$domain\""
fi

exit 0
