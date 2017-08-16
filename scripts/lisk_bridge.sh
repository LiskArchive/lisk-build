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

# Reads in programatic variables if not the default
parseOption() {
	OPTIND=1
	while getopts :s:b:n:h: OPT; do
		 case "$OPT" in
			 s) LISK_HOME="$OPTARG" ;; # Where lisk is installed
			 b) BRIDGE_HOME="$OPTARG" ;; # Where the bridge is located
			 n) BRIDGE_NETWORK="$OPTARG" ;; # Which network is being bridged
			 h) TARGET_HEIGHT="$OPTARG" ;; # What height to cut over at
		 esac
	 done
}

# This function harvests the configuation data from the source
# installation for an automated cutover.
extractConfig() {
  PM2_CONFIG="$LISK_HOME/etc/pm2-lisk.json"
  LISK_CONFIG="$(grep "config" "$PM2_CONFIG" | cut -d'"' -f4 | cut -d' ' -f2)" >> /dev/null
	PORT="$(grep "port" "$LISK_CONFIG" | head -1 | cut -d':' -f 2 | cut -d',' -f 1 | tr -d '[:space:]')"
}

# This function queries the `/api/loader/status/sync` endpoint
# and extracts the height for evaluation.
blockMonitor() {
  BLOCK_HEIGHT="$(curl -s http://localhost:"$PORT"/api/loader/status/sync | cut -d':' -f 5 | cut -d',' -f 1)"
}

# This function terminates the lisk client at the assigned blocks
# preparing the installation for a cutover.
terminateLisk() {
	bash "$LISK_HOME/lisk.sh" stop
}

# Downloads the new lisk client.
downloadLisk() {
	wget "https://downloads.lisk.io/lisk/$BRIDGE_NETWORK/installLisk.sh"
}

# This function executes the migration of the source installation
# and deploys the target installation, minimizing downtime.
migrateLisk() {
	bash "$(pwd)/installLisk.sh" upgrade -r "$BRIDGE_NETWORK" -d "$LISK_HOME" -0 no
}

# Sets up initial configuration and first call to the application
# to establish baseline statistics.
parseOption
extractConfig
blockMonitor

# This function acts as our eventloop, keeping the process running
# in order to monitor the node for upgrade.
while [[ "$BLOCK_HEIGHT" -lt "$TARGET_HEIGHT" ]] ; do
	blockMonitor
	echo "$BLOCK_HEIGHT"
	sleep 5
done

cd "$LISK_HOME" || exit 2
terminateLisk
cd "$BRIDGE_HOME"  || exit 2
downloadLisk
migrateLisk

# All done!
