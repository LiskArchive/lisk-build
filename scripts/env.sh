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

# Binary paths
export PATH="$PWD/bin:$PWD/pgsql/bin:$PWD/node/bin:$PWD/lisky/bin:$PWD/pm2/bin:$PATH"

# Load dynamic libaries paths
export LD_LIBRARY_PATH="$PWD/pgsql/lib:$PWD/lib:$PWD/node/lib:$LD_LIBRARY_PATH"

# PM2 home directory
export PM2_HOME="$PWD/.pm2"

# Node libraries path
export NODE_PATH="$PWD/node/lib"
