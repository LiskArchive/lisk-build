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

if [ ! "$(uname -s)" == "Darwin" ]; then
	echo "Invalid operating system. Aborting."
	exit 1
fi

# shellcheck disable=SC2034
# Ignoring the failure due to shell indirection
CMDS=("ruby" "curl")
check_cmds CMDS[@]

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
exec_cmd "brew install autoconf automake bison git libtool md5sha1sum n postgresql wget"
exec_cmd "brew link bison --force"
exec_cmd "sudo n v6.12.2"
