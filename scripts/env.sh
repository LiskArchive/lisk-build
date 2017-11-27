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

# We dont care about return code here
# shellcheck disable=SC2155
export PATH="$(pwd)/bin:$(pwd)/pgsql/bin:$PATH"
# We dont care about return code here
# shellcheck disable=SC2155
export LD_LIBRARY_PATH="$(pwd)/pgsql/lib:$(pwd)/lib:$LD_LIBRARY_PATH"
# We dont care about return code here
# shellcheck disable=SC2155
export PM2_HOME=$(pwd)/.pm2
