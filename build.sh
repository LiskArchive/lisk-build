#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
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

CLEAN=false
OPTIND=1
while getopts "cn:v:" OPT; do
	case "$OPT" in
		c) CLEAN=true;;
		n) LISK_NETWORK="$OPTARG";;
		v) VERSION="$OPTARG";;
		:) echo 'Missing option argument for -'"$OPTARG" >&2; exit 1;;
		*) echo 'Unimplemented option: -'"$OPTARG" >&2; exit 1;;
	esac
done

if [[ $VERSION && $LISK_NETWORK ]]; then
	echo "Building version $VERSION for ${LISK_NETWORK}net."
else
	echo "Both -n and -v are required. Exiting."
	exit 1
fi

# shellcheck source=./config.sh
. "$(pwd)/config.sh"

if [[ "$CLEAN" == true ]]; then
	echo "Cleaning build."
	rm -rf "src/$BUILD_NAME"
fi

################################################################################

# Requirements for Ubuntu 14.04.5 LTS base install:
# apt-get install build-essential autoconf libtool zlib1g-dev \
#     valgrind \  # jq tests
#     tcl8.5 \    # redis tests
#     moreutils   # used below

pushd src

if [ ! -f "$LISK_FILE" ]; then
	echo "$LISK_FILE needs to be copied to src/"
	exit 2
fi

echo
echo "Downloading and building jq..."
echo "--------------------------------------------------------------------------"
[[ -f "$JQ_FILE" ]] || wget -nv "$JQ_URL" --output-document="$JQ_FILE"
echo "$JQ_SHA256SUM  $JQ_FILE" |sha256sum -c
if [ ! -f "$JQ_DIR/finished" ]; then
	rm -rf $JQ_DIR
	tar xf $JQ_FILE
	pushd "$JQ_DIR"
	./configure --disable-docs
	# ensure oniguruma is not used
	grep --quiet 'ac_cv_header_oniguruma_h=no' config.log
	make
	# https://github.com/stedolan/jq/issues/1091
	sed --in-place 's# tests/onigtest##' Makefile
	make check
	touch finished
	popd
fi

echo
echo "Downloading and building redis..."
echo "--------------------------------------------------------------------------"
[[ -f "$REDIS_SERVER_FILE" ]] || wget -nv "$REDIS_SERVER_URL" --output-document="$REDIS_SERVER_FILE"
echo "$REDIS_SHA256SUM  $REDIS_SERVER_FILE" |sha256sum -c
if [ ! -f "$REDIS_SERVER_DIR/finished" ]; then
	rm -rf $REDIS_SERVER_DIR
	tar xf $REDIS_SERVER_FILE
	pushd "$REDIS_SERVER_DIR"
	make
	make check
	touch finished
	popd
fi

echo
echo "Downloading postgresql..."
echo "--------------------------------------------------------------------------"
[[ -f "$POSTGRESQL_FILE" ]] || wget -nv "$POSTGRESQL_BIN_URL" --output-document="$POSTGRESQL_FILE"
echo "$POSTGRESQL_SHA256SUM  $POSTGRESQL_FILE" |sha256sum -c

echo
echo "Downloading node..."
echo "--------------------------------------------------------------------------"
[[ -f "$NODE_FILE" ]] || wget -nv "$NODE_BIN_URL" --output-document="$NODE_FILE"
echo "$NODE_SHA256SUM  $NODE_FILE" |sha256sum -c

echo
echo "Installing lisk-scripts..."
echo "--------------------------------------------------------------------------"
[[ -f "$LISK_SCRIPTS_FILE" ]] || wget -nv "$LISK_SCRIPTS_URL" --output-document="$LISK_SCRIPTS_FILE"
echo "$LISK_SCRIPTS_SHA256SUM  $LISK_SCRIPTS_FILE" |sha256sum -c
if [ ! -f "$LISK_SCRIPTS_DIR/finished" ]; then
	rm -rf "$LISK_SCRIPTS_DIR"
	tar xf "$LISK_SCRIPTS_FILE"
	touch "$LISK_SCRIPTS_DIR/finished"
fi

echo
echo "Building lisk..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$BUILD_NAME/finished" ]; then
	rm -rf "$BUILD_NAME"
	tar xf "lisk-$VERSION.tgz"
	mv package "$BUILD_NAME"
	mkdir -p "$BUILD_NAME"/{bin,lib,logs,pids}

	# extract postgresql
	tar xf "$POSTGRESQL_FILE" --directory="$BUILD_NAME" \
	    --exclude=doc --exclude=include --exclude="pgAdmin 4" --exclude=stackbuilder

	# copy redis binaries
	cp -f "$REDIS_SERVER_DIR/src/$REDIS_SERVER_OUT" "$BUILD_NAME/bin/$REDIS_SERVER_OUT"
	cp -f "$REDIS_SERVER_DIR/src/$REDIS_SERVER_CLI" "$BUILD_NAME/bin/$REDIS_SERVER_CLI"
	# create redis workding directory
	mkdir -p "$BUILD_NAME/redis"

	# copy jq binary
	cp -f "$JQ_DIR/$JQ_OUT" "$BUILD_NAME/bin/$JQ_OUT"

	# copy lisk "packaged" scripts
	cp -vrf "$LISK_SCRIPTS_DIR/packaged/"* "$BUILD_NAME"

	# extract nodejs
	tar xf "$NODE_FILE" --strip-components=1 --directory="$BUILD_NAME"

	pushd "$BUILD_NAME"

	echo "Setting LISK_NETWORK in env.sh..."
	echo "--------------------------------------------------------------------------"
	echo "export LISK_NETWORK=${LISK_NETWORK}net" >>env.sh

	echo "Create default custom config.json..."
	echo "--------------------------------------------------------------------------"
	echo '{}' >config.json

	echo "Creating etc/snapshot.json..."
	echo "--------------------------------------------------------------------------"
	cp config.json etc/snapshot.json
	"./bin/$JQ_OUT" '.httpPort=9000' etc/snapshot.json |sponge etc/snapshot.json
	"./bin/$JQ_OUT" '.wsPort=9001' etc/snapshot.json |sponge etc/snapshot.json
	"./bin/$JQ_OUT" '.logFileName="logs/lisk_snapshot.log"' etc/snapshot.json |sponge etc/snapshot.json
	"./bin/$JQ_OUT" '.fileLogLevel="info"' etc/snapshot.json |sponge etc/snapshot.json
	"./bin/$JQ_OUT" '.db.database="lisk_snapshot"' etc/snapshot.json |sponge etc/snapshot.json
	"./bin/$JQ_OUT" '.peers.list=[]' etc/snapshot.json |sponge etc/snapshot.json
	"./bin/$JQ_OUT" '.loading.loadPerIteration=101' etc/snapshot.json |sponge etc/snapshot.json

	echo "Installing lisk..."
	echo "--------------------------------------------------------------------------"
	set +u
	# shellcheck disable=SC1090
	. "$(pwd)/env.sh"
	set -u
	npm install --production

	echo "Installing pm2 and lisk-commander..."
	echo "--------------------------------------------------------------------------"
	npm install --production --global "pm2@$PM2_VERSION"
	npm install --production --global "lisk-commander@$LISK_COMMANDER_VERSION"

	date >finished
	popd
fi

echo
echo "Creating tarballs..."
echo "--------------------------------------------------------------------------"
rm -rf ../release/*
tar czf "../release/$BUILD_NAME.tar.gz" "$BUILD_NAME"
# TODO: will fail on xenial (coreutils 8.25) if there are dangling symlinks
cp -rl "$BUILD_NAME" "$NOVER_BUILD_NAME"
tar czf "../release/$NOVER_BUILD_NAME.tar.gz" "$NOVER_BUILD_NAME"
rm -rf "$NOVER_BUILD_NAME"

echo
echo "Creating checksums of tarballs..."
echo "--------------------------------------------------------------------------"
pushd ../release
sha256sum "$BUILD_NAME.tar.gz" >"$BUILD_NAME.tar.gz.SHA256"
sha256sum "$NOVER_BUILD_NAME.tar.gz" >"$NOVER_BUILD_NAME.tar.gz.SHA256"
popd
popd
