#!/bin/bash
# LiskHQ/lisk-bridge
#
# Connects source and target versions of Lisk in order to migrate
# gracefully between protocol changes.
#
# Copyright (C) 2017 Lisk Foundation
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
######################################################################

# Declare working variables
TARGET_HEIGHT="3513100"
BRIDGE_HOME="$(pwd)"
BRIDGE_NETWORK="main"
LISK_HOME="$HOME/lisk-main"

# Reads in required variables if configured by the user.
parseOption() {
	OPTIND=1
	while getopts ":s:b:n:h:" OPT; do
		case "$OPT" in
			 s) LISK_HOME="$OPTARG" ;; # Where lisk is installed
			 b) BRIDGE_HOME="$OPTARG" ;; # Where the bridge is located
			 n) BRIDGE_NETWORK="$OPTARG" ;; # Which network is being bridged
			 h) TARGET_HEIGHT="$OPTARG" ;; # What height to cut over at
		 esac
	 done
}

# Harvests the configuation data from the source installation
# for an automated cutover.
extractConfig() {
	PM2_CONFIG="$LISK_HOME/etc/pm2-lisk.json"
	LISK_CONFIG="$(grep "config" "$PM2_CONFIG" | cut -d'"' -f4 | cut -d' ' -f2)" >> /dev/null
	LISK_CONFIG="$LISK_HOME/$LISK_CONFIG"
	export PORT
	PORT="$(grep "port" "$LISK_CONFIG" | head -1 | cut -d':' -f 2 | cut -d',' -f 1 | tr -d '[:space:]')"

	readarray secrets < <(jq -r '.forging.secret | .[]' "$LISK_CONFIG")
	for i in $(seq 0 ${#secrets[@]}); do
		secrets[$i]=$(echo "${secrets[$i]}" | tr -d '\n')
	done
}

# Queries the `/api/loader/status/sync` endpoint
# and extracts the height for evaluation.
blockMonitor() {
  BLOCK_HEIGHT="$(curl -s http://localhost:"$PORT"/api/loader/status/sync | cut -d':' -f 5 | cut -d',' -f 1)"
}

# Terminates the lisk client at the assigned blocks
# preparing the installation for a cutover.
terminateLisk() {
	bash "$LISK_HOME/lisk.sh" stop
}

# Downloads the new Lisk client.
downloadLisk() {
	wget "https://downloads.lisk.io/lisk/$BRIDGE_NETWORK/installLisk.sh"
}

# Executes the migration of the source installation
# and deploys the target installation, minimizing downtime.
migrateLisk() {
	bash "$(pwd)/installLisk.sh" upgrade -r "$BRIDGE_NETWORK" -s "$LISK_HOME" -d "$BRIDGE_HOME" -c "$BRIDGE_HOME/new_config.json" -0 no
}

# Migrates the secrets in config.json to an encrypted format,
# prompting user for a master password.
passphraseMigration() {
	echo -e "This next step will migrate the secrets in config.json to an encrypted format\nYou will be prompted for a master password\n"
	read -r -p "$(echo -e "Press Enter to continue\n\b")"
	read -r -p "$(echo -e "Please enter the master password\n\b")" master_password
	read -r -p "$(echo -e "Please enter the master password again\n\b")" master_password2

	if [[ "$master_password" != "$master_password2" ]]; then
		echo "Passwords don't match. Exiting..."
		exit 1
	fi

	jq ".forging.defaultKey += \"$master_password\"" "$LISK_CONFIG" > new_config.json
	for i in $(seq 0 ${#secrets[@]}); do
		temp=$(echo "${secrets[$i]}" | tr -d '\n' | openssl enc -aes-256-cbc -k "$master_password" -nosalt | od -A n -t x1)
		temp=${temp// /}
		temp=$(echo "$temp" | tr -d '\n')
		if [[ "${#secrets[$i]}" -eq 0 ]]; then
			continue;
		fi
		jq '.forging.secret += [{ "encryptedSecret": "'"$temp"'"}]' new_config.json > new_config2.json
		mv new_config2.json new_config.json
	done
}

# Sets up initial configuration and first call to the application
# to establish baseline statistics.
parseOption "$@"
extractConfig
blockMonitor

# Acts as the eventloop, keeping the process running
# in order to monitor the node for upgrade.
while [[ "$BLOCK_HEIGHT" -lt "$TARGET_HEIGHT" ]] ; do
	blockMonitor
	echo "$BLOCK_HEIGHT"
	sleep 5
done

cd "$LISK_HOME" || exit 2
terminateLisk
cd "$BRIDGE_HOME"  || exit 2
passphraseMigration
downloadLisk
migrateLisk

# All done!
