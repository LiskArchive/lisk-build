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

parse_option() {
	OPTIND=1
	while getopts "v:n:" OPT; do
		case "$OPT" in
			v ) export VERSION="$OPTARG";;
			n ) export LISK_NETWORK="$OPTARG";;
			: ) echo 'Missing option argument for -'"$OPTARG" >&2; exit 1;;
			* ) echo 'Unimplemented option: -'"$OPTARG" >&2; exit 1;;
		esac
	done

	if [[ $VERSION && $LISK_NETWORK ]]; then
		echo "All options declared. Proceeding with build."
	else
		echo "Both -n and -v are required. Exiting."
		exit 1
	fi
}

# Parse options for network and version
parse_option "$@"

# shellcheck source=./shared.sh
. "$(pwd)/shared.sh"
# shellcheck source=./config.sh
. "$(pwd)/config.sh"

# shellcheck disable=SC2034
# Ignoring the failure due to shell indirection
CMDS=("autoconf" "gcc" "g++" "make" "node" "npm" "python" "tar" "wget");
check_cmds CMDS[@]

mkdir -p src
# Exit 2 in case the directory doesnt exist and preventing messes
cd src || exit 2

################################################################################

echo "Building libreadline7"
echo "--------------------------------------------------------------------------"
if [ ! -f "$LIBREADLINE_FILE" ] && [ ! "$(uname -s)" == "Darwin" ]; then
	exec_cmd "wget $LIBREADLINE_URL -O $LIBREADLINE_FILE"
fi
if [ ! -f "$LIBREADLINE_DIR/shlib/$LIBREADLINE_OUT" ] && [ ! "$(uname -s)" == "Darwin" ]; then
	exec_cmd "rm -rf $LIBREADLINE_DIR"
	exec_cmd "tar -zxf $LIBREADLINE_FILE"
	cd "$LIBREADLINE_DIR" || exit 2
	exec_cmd "./configure"
	exec_cmd "make --jobs=$JOBS SHLIB_LIBS=-lcurses"
	exec_cmd "sudo make install"
	cd ../ || exit 2
fi

echo "Building jq"
echo "--------------------------------------------------------------------------"
if [ ! -f "$JQ_FILE" ]; then
	exec_cmd "wget $JQ_URL -O $JQ_FILE"
fi
if [ ! -f "$JQ_DIR/$JQ_OUT" ]; then
	exec_cmd "rm -rf $JQ_DIR"
	exec_cmd "tar -zxf $JQ_FILE"
	cd "$JQ_DIR" || exit 2
	exec_cmd "./configure"
	exec_cmd "make"
	cd ../ || exit 2
fi

echo "Building postgresql..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$POSTGRESQL_FILE" ]; then
	exec_cmd "wget $POSTGRESQL_URL -O $POSTGRESQL_FILE"
fi
if [ ! -f "$POSTGRESQL_DIR/$POSTGRESQL_OUT/bin/psql" ]; then
	exec_cmd "rm -rf $POSTGRESQL_DIR"
	exec_cmd "tar -zxf $POSTGRESQL_FILE"
	cd "$POSTGRESQL_DIR" || exit 2

	# Configures make for libreadline7 on linux, without for Darwin
	if [ ! "$(uname -s)" == "Darwin" ]; then
		exec_cmd "./configure --prefix=$(pwd)/$POSTGRESQL_OUT --with-libs=/usr/local/lib --with-includes=/usr/local/include"
	else
		exec_cmd "./configure --prefix=$(pwd)/$POSTGRESQL_OUT"
	fi

	exec_cmd "make --jobs=$JOBS"
	exec_cmd "make install"

	# Compiles the pgcrypto extension
	cd "$(pwd)/contrib/pgcrypto" || exit 2
	exec_cmd "make"
	exec_cmd "make install"

	cd ../../.. || exit 2
fi

echo "Building Redis-Server"
echo "--------------------------------------------------------------------------"
if [ ! -f "$REDIS_SERVER_FILE" ]; then
	exec_cmd "wget $REDIS_SERVER_URL -O $REDIS_SERVER_FILE"
fi
if [ ! -f "$REDIS_SERVER_DIR/src/$REDIS_SERVER_OUT" ]; then
	exec_cmd "rm -rf $REDIS_SERVER_DIR"
	exec_cmd "tar -zxf $REDIS_SERVER_FILE"
	cd "$REDIS_SERVER_DIR" || exit 2
	exec_cmd "make --jobs=$JOBS $REDIS_SERVER_CONFIG"
	cd ../ || exit 2
fi

echo "Building lisk..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$LISK_FILE" ]; then
	exec_cmd "wget $LISK_URL -O $LISK_FILE"
fi
if [ ! -d "$BUILD_NAME/node_modules" ]; then
 	if [ -d "$BUILD_NAME/node_modules" ]; then
					exec_cmd "rm -rf $BUILD_NAME"
	fi
	exec_cmd "mkdir $BUILD_NAME"
	exec_cmd "tar -xf $LISK_FILE --directory $BUILD_NAME"
	exec_cmd "cp -vRf $POSTGRESQL_DIR/$POSTGRESQL_OUT $BUILD_NAME/"
	exec_cmd "mkdir $BUILD_NAME/bin"
	exec_cmd "mkdir $BUILD_NAME/lib"

	# Create redis specific dirs and copy binaries
	exec_cmd "mkdir $BUILD_NAME/redis"
	exec_cmd "cp -vf $REDIS_SERVER_DIR/src/$REDIS_SERVER_OUT $BUILD_NAME/bin/$REDIS_SERVER_OUT"
	exec_cmd "cp -vf $REDIS_SERVER_DIR/src/$REDIS_SERVER_CLI $BUILD_NAME/bin/$REDIS_SERVER_CLI"

	# Copy jq to binary folder
	exec_cmd "cp -vf $JQ_DIR/$JQ_OUT $BUILD_NAME/bin/$JQ_OUT"

	# Copy Libpq for use
	exec_cmd "sudo cp -v $BUILD_NAME/pgsql/lib/libpq.* /usr/lib"

	# Bundle libreadline6 and create symbolic links
	if [ ! "$(uname -s)" == "Darwin" ]; then
	exec_cmd "cp -vf $LIBREADLINE_DIR/shlib/lib*.so.* $BUILD_NAME/lib"
	exec_cmd "cp -vf $LIBREADLINE_DIR/lib*.a $BUILD_NAME/lib"
	cd "$(pwd)/$BUILD_NAME/lib" || exit 2
	exec_cmd "ln -s $LIBREADLINE_OUT libreadline.so.7"
	exec_cmd "ln -s libreadline.so.7 libreadline.so"
	exec_cmd "ln -s $LIBREADLINE_HISTORY libhistory.so.7"
	exec_cmd "ln -s libhistory.so.7 libhistory.so"
	cd ../../ || exit 2
	fi

	cd "$BUILD_NAME" || exit 2
	exec_cmd "npm install --production $LISK_CONFIG"

	if [[ "$(uname)" == "Linux" ]]; then
	chrpath -d "$(pwd)/node_modules/sodium/deps/libsodium/test/default/.libs/"*
	chrpath -d "$(pwd)/lib/libreadline.so.7.0"
	chrpath -d "$(pwd)/lib/libhistory.so.7.0"
	fi # Change rpaths on linux

	cd ../ || exit 2
fi

echo "Installing lisk-scripts..."
echo "--------------------------------------------------------------------------"
exec_cmd "wget $LISK_SCRIPTS_URL -O $LISK_SCRIPTS_FILE"
exec_cmd "tar -zxvf $LISK_SCRIPTS_FILE"
exec_cmd "cp -vRf $LISK_SCRIPTS_DIR/packaged/* $BUILD_NAME"

echo "Building node..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$NODE_FILE" ]; then
	exec_cmd "wget $NODE_URL -O $NODE_FILE"
fi
if [ ! -f "$NODE_DIR/$NODE_OUT/bin/node" ] || [ ! -f "$NODE_DIR/$NODE_OUT/bin/npm" ]; then
	exec_cmd "rm -rf $NODE_DIR"
	exec_cmd "tar -zxvf $NODE_FILE"
	cd "$NODE_DIR" || exit 2
	apply_patches "node"
	exec_cmd "./configure --prefix=$(pwd)/compiled $NODE_CONFIG"
	exec_cmd "make --jobs=$JOBS"
	exec_cmd "make install"
	cd ../ || exit 2
fi
exec_cmd "cp -vRf $NODE_DIR/$NODE_OUT/* $BUILD_NAME/"
exec_cmd "sed $SED_OPTS \"s%$(head -1 "$NPM_CLI")%#\!.\/bin\/node%g\" $NPM_CLI"

cd "$BUILD_NAME" || exit 2

echo "Installing PM2 and Lisky..."
echo "--------------------------------------------------------------------------"
# shellcheck disable=SC1090
. "$(pwd)/env.sh"

exec_cmd "npm install --global --production pm2"
exec_cmd "npm install --global --production lisky"
# Add symbolic link to lisky from root dir
exec_cmd "ln -s ./bin/lisky lisky"
cd ../ || exit 2

echo "Stamping build..."
echo "--------------------------------------------------------------------------"
exec_cmd "echo v$(date '+%H:%M:%S %d/%m/%Y') > $BUILD_NAME/package.build";

echo "Creating archives..."
echo "--------------------------------------------------------------------------"
# Create $BUILD_NAME.tar.gz
exec_cmd "GZIP=-6 tar -czf ../release/$BUILD_NAME.tar.gz $BUILD_NAME"

# Create $NOVER_BUILD_NAME.tar.gz
exec_cmd "mv -f $BUILD_NAME $NOVER_BUILD_NAME"
exec_cmd "GZIP=-6 tar -czf ../release/$NOVER_BUILD_NAME.tar.gz $NOVER_BUILD_NAME"

# Create lisk-source.tar.gz
exec_cmd "mv -f $VERSION lisk-source"
exec_cmd "GZIP=-6 tar -czf ../release/lisk-source.tar.gz lisk-source"

echo "Checksumming archives..."
echo "--------------------------------------------------------------------------"
cd ../release || exit 2
exec_cmd "$SHA_CMD $BUILD_NAME.tar.gz > $BUILD_NAME.tar.gz.SHA256"
exec_cmd "$SHA_CMD $NOVER_BUILD_NAME.tar.gz > $NOVER_BUILD_NAME.tar.gz.SHA256"
exec_cmd "$SHA_CMD lisk-source.tar.gz > lisk-source.tar.gz.SHA256"
cd ../src || exit 2

echo "Cleaning up..."
echo "--------------------------------------------------------------------------"
exec_cmd "rm -rf $BUILD_NAME $NOVER_BUILD_NAME lisk-source"
cd ../ || exit 2
