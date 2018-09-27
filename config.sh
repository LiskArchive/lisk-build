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

# shellcheck disable=SC2034

VERSION="$VERSION"
OS=$(uname)
ARCH="${ARCH:-$( uname -m )}"
BUILD_NAME="lisk-$VERSION-$OS-$ARCH"
NOVER_BUILD_NAME="lisk-$OS-$ARCH"
TARGET=""

ncpu=$( grep -c processor /proc/cpuinfo )
ncpu=$(( ncpu + 0 ))
tcpu=$(( ncpu / 2 + 1 ))
[[ $tcpu -gt 8 ]] && tcpu=8
MAKEOPTS="-j${tcpu}"

LISK_DIR="$VERSION"
LISK_FILE="lisk-$VERSION.tgz"
LISK_NETWORK="$LISK_NETWORK"
LISK_URL="https://downloads.lisk.io/lisk/$LISK_NETWORK/$VERSION/$LISK_FILE"

LISK_SCRIPTS_VERSION="0.3.2"
LISK_SCRIPTS_SHA256SUM="f3b7a2b694b225e68e16f802fcdc8d0b17067210b713f52cd6032ff417f92e5a"
LISK_SCRIPTS_DIR="lisk-scripts-$LISK_SCRIPTS_VERSION"
LISK_SCRIPTS_FILE="$LISK_SCRIPTS_DIR.tar.gz"
LISK_SCRIPTS_URL="https://github.com/LiskHQ/lisk-scripts/archive/v$LISK_SCRIPTS_VERSION.tar.gz"

NODE_VERSION="6.14.1"
NODE_SHA256SUM="82ca9917819db13c3a3484bd2bee1c58cd718aec3e4ad46026f968557a6717be"
NODE_DIR="node-v$NODE_VERSION"
NODE_FILE="$NODE_DIR.tar.gz"
NODE_URL="https://nodejs.org/download/release/v$NODE_VERSION/$NODE_FILE"
NODE_OUT="compiled"

POSTGRESQL_VERSION="10.5"
POSTGRESQL_SHA256SUM="13be7053b1d8ad4e24943b24d80170574fc701b49b3f14e68a5f1bda452ce3d1"
POSTGRESQL_DIR="postgresql-$POSTGRESQL_VERSION"
POSTGRESQL_FILE="$POSTGRESQL_DIR.tar.gz"
POSTGRESQL_URL="https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/$POSTGRESQL_FILE"
POSTGRESQL_OUT="pgsql"

REDIS_VERSION="4.0.11"
REDIS_SHA256SUM="fc53e73ae7586bcdacb4b63875d1ff04f68c5474c1ddeda78f00e5ae2eed1bbb"
REDIS_SERVER_DIR="redis-$REDIS_VERSION"
REDIS_SERVER_FILE="$REDIS_SERVER_DIR.tar.gz"
REDIS_SERVER_URL="http://download.redis.io/releases/$REDIS_SERVER_FILE"
REDIS_SERVER_OUT="redis-server"
REDIS_SERVER_CLI="redis-cli"

JQ_VERSION="1.5"
JQ_SHA256SUM="c4d2bfec6436341113419debf479d833692cc5cdab7eb0326b5a4d4fbe9f493c"
JQ_DIR="jq-$JQ_VERSION"
JQ_FILE="$JQ_DIR.tar.gz"
JQ_URL="https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/$JQ_FILE"
JQ_OUT="jq"

NPM_CLI="$BUILD_NAME/lib/node_modules/npm/bin/npm-cli.js"

PM2_VERSION=3.1.3
LISK_COMMANDER_VERSION=1.0.0
