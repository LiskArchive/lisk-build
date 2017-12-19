#!/bin/bash
# 
# LiskHQ/lisk-build
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

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2
# shellcheck disable=SC1090
. "$(pwd)/../shared.sh"

if [ ! "$(uname -s)" == "Linux" ]; then
	echo "Invalid operating system. Aborting."
	exit 1
fi

# shellcheck disable=SC2034
# Ignoring the failure due to shell indirection
CMDS=("apt-get" "curl" "sudo")
check_cmds CMDS[@]

exec_cmd "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash"
export NVM_DIR="/home/$USER/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
nvm install v6.12.2
exec_cmd "sudo apt-get install -y autoconf automake build-essential curl chrpath git libreadline6-dev libtool zlib1g-dev libssl-dev libpq-dev nodejs python wget libncurses5-dev"
