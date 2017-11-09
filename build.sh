#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

parse_option() {
	OPTIND=1
	while getopts "m:t:" OPT; do
		case "$OPT" in
			m ) export MAIN_VERSION="$OPTARG";;
			t ) export TEST_VERSION="$OPTARG";;
			: ) echo 'Missing option argument for -'"$OPTARG" >&2; exit 1;;
			* ) echo 'Unimplemented option: -'"$OPTARG" >&2; exit 1;;
		esac
	done

	if [[ $MAIN_VERSION && $TEST_VERSION ]]; then
		echo "All options declared. Proceeding with build."
	else
		echo "Both -m and -t are required. Exiting"
		exit 1
	fi
}

# Parse options for network and version
parse_option "$@"

# shellcheck source=./shared.sh
. "$(pwd)/shared.sh"

# shellcheck source=./config.sh
. "$(pwd)/config.sh"

# Initialize variables
ROOT_DIR="$(pwd)"
SRC_DIR="$(pwd)/src"

# shellcheck disable=SC2034
# Ignoring the failure due to shell indirection
CMDS=("autoconf" "gcc" "g++" "make" "node" "npm" "python" "tar" "wget");
check_cmds CMDS[@]

# Create directories and cleanup failed builds
exec_cmd "mkdir -p src"
exec_cmd "rm -rf $SRC_DIR/$BUILD_NAME && mkdir -p $SRC_DIR/$BUILD_NAME"
exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/bin"
exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/lib"

# Exit 2 in case the directory doesn't exist and preventing messes
cd "$SRC_DIR" || exit 2

################################################################################

echo "Building libreadline7"
echo "--------------------------------------------------------------------------"
if [ ! -f "$SRC_DIR/$LIBREADLINE_FILE" ] && [ ! "$(uname -s)" == "Darwin" ]; then
	exec_cmd "wget $LIBREADLINE_URL -O $LIBREADLINE_FILE"
fi
if [ ! -f "$SRC_DIR/$LIBREADLINE_DIR/shlib/$LIBREADLINE_OUT" ] && [ ! "$(uname -s)" == "Darwin" ]; then
	exec_cmd "rm -rf $LIBREADLINE_DIR"
	exec_cmd "tar -zxf $LIBREADLINE_FILE"
	cd "$SRC_DIR/$LIBREADLINE_DIR" || exit 2
	exec_cmd "./configure"
	exec_cmd "make --jobs=$JOBS SHLIB_LIBS=-lcurses"
	exec_cmd "sudo make install"
	cd "$SRC_DIR" || exit 2
fi

echo "Building postgresql..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$SRC_DIR/$POSTGRESQL_FILE" ]; then
	exec_cmd "wget $POSTGRESQL_URL -O $SRC_DIR/$POSTGRESQL_FILE"
fi
if [ ! -f "$SRC_DIR/$POSTGRESQL_DIR/$POSTGRESQL_OUT/bin/psql" ]; then
	exec_cmd "rm -rf $SRC_DIR/$POSTGRESQL_DIR"
	exec_cmd "tar -zxf $SRC_DIR/$POSTGRESQL_FILE"
	cd "$SRC_DIR/$POSTGRESQL_DIR" || exit 2

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

	cd "$SRC_DIR" || exit 2
fi

echo "Building Redis-Server"
echo "--------------------------------------------------------------------------"
if [ ! -f "$SRC_DIR/$REDIS_SERVER_FILE" ]; then
	exec_cmd "wget $REDIS_SERVER_URL -O $SRC_DIR/$REDIS_SERVER_FILE"
fi
if [ ! -f "$SRC_DIR/$REDIS_SERVER_DIR/src/$REDIS_SERVER_OUT" ]; then
	exec_cmd "rm -rf $SRC_DIR/$REDIS_SERVER_DIR"
	exec_cmd "tar -zxf $SRC_DIR/$REDIS_SERVER_FILE"
	cd "$SRC_DIR/$REDIS_SERVER_DIR" || exit 2
	exec_cmd "make --jobs=$JOBS $REDIS_SERVER_CONFIG"
	cd "$SRC_DIR" || exit 2
fi

echo "Building jq"
echo "--------------------------------------------------------------------------"
	if [ ! -f "$SRC_DIR/$JQ_FILE" ]; then
		exec_cmd "wget $JQ_URL -O $SRC_DIR/$JQ_FILE"
	fi
	if [ ! -f "$SRC_DIR/$JQ_DIR/$JQ_OUT" ]; then
		exec_cmd "rm -rf $SRC_DIR/$JQ_DIR"
		exec_cmd "tar -zxf $SRC_DIR/$JQ_FILE"
		cd "$SRC_DIR/$JQ_DIR" || exit 2
		exec_cmd "./configure $JQ_CONFIG"
		exec_cmd "make"
		cd "$SRC_DIR" || exit 2
	fi

echo "Building node..."
echo "--------------------------------------------------------------------------"
cd "$SRC_DIR" || exit 2

if [ ! -f "$NODE_FILE" ]; then
	exec_cmd "wget $NODE_URL -O $NODE_FILE"
fi
if [ ! -f "$SRC_DIR/$NODE_DIR/$NODE_OUT/bin/node" ] || [ ! -f "$SRC_DIR/$NODE_DIR/$NODE_OUT/bin/npm" ]; then
	exec_cmd "rm -rf $SRC_DIR/$NODE_DIR"
	exec_cmd "tar -zxf $SRC_DIR/$NODE_FILE"
	cd "$SRC_DIR/$NODE_DIR" || exit 2
	apply_patches "node"
	exec_cmd "./configure --prefix=$(pwd)/compiled $NODE_CONFIG"
	exec_cmd "make --jobs=$JOBS"
	exec_cmd "make install"
	cd "$SRC_DIR" || exit 2
fi

echo "Copying scripts..."
echo "--------------------------------------------------------------------------"
exec_cmd "cp -f $ROOT_DIR/shared.sh $ROOT_DIR/scripts/*.sh $SRC_DIR/$BUILD_NAME/"
exec_cmd "cp -f $ROOT_DIR/scripts/*.js $SRC_DIR/$BUILD_NAME/bin/"
exec_cmd "cp -fR $ROOT_DIR/etc $SRC_DIR/$BUILD_NAME/"

echo "Copying binaries into place"
echo "--------------------------------------------------------------------------"
cd "$SRC_DIR" || exit 2

# Copy PostgreSQL to binary root
exec_cmd "cp -R $SRC_DIR/$POSTGRESQL_DIR/$POSTGRESQL_OUT $SRC_DIR/$BUILD_NAME/"

# Create redis specific dirs and copy binaries
exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/redis"
exec_cmd "cp -vf $SRC_DIR/$REDIS_SERVER_DIR/src/$REDIS_SERVER_OUT $SRC_DIR/$BUILD_NAME/bin/$REDIS_SERVER_OUT"
exec_cmd "cp -vf $SRC_DIR/$REDIS_SERVER_DIR/src/$REDIS_SERVER_CLI $SRC_DIR/$BUILD_NAME/bin/$REDIS_SERVER_CLI"

# Copy jq to binary root
exec_cmd "cp -vf $SRC_DIR/$JQ_DIR/$JQ_OUT $SRC_DIR/$BUILD_NAME/bin/$JQ_OUT"

# Copy node to binary root
exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/node"
exec_cmd "cp -R $SRC_DIR/$NODE_DIR/$NODE_OUT/* $SRC_DIR/$BUILD_NAME/node"

# Make log dir for future use in Full Installing
exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/logs"

# Copy libreadline7 and create symbolic links
if [ ! "$(uname -s)" == "Darwin" ]; then
	exec_cmd "cp -vf $SRC_DIR/$LIBREADLINE_DIR/shlib/lib*.so.* $SRC_DIR/$BUILD_NAME/lib"
	exec_cmd "cp -vf $SRC_DIR/$LIBREADLINE_DIR/lib*.a $SRC_DIR/$BUILD_NAME/lib"
	cd "$SRC_DIR/$BUILD_NAME/lib" || exit 2
	exec_cmd "ln -s $LIBREADLINE_OUT libreadline.so.7"
	exec_cmd "ln -s libreadline.so.7 libreadline.so"
	exec_cmd "ln -s $LIBREADLINE_HISTORY libhistory.so.7"
	exec_cmd "ln -s libhistory.so.7 libhistory.so"
	cd "$SRC_DIR" || exit 2
fi

echo "Installing PM2 and Lisky..."
echo "--------------------------------------------------------------------------"
cd "$SRC_DIR/$BUILD_NAME" || exit 2
# shellcheck disable=SC1090
. "$(pwd)/env.sh"

# Required to build sodium
exec_cmd "npm install -g npm@5.3.0"

# Create PM2 directory and install there
exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/pm2"
cd "$SRC_DIR/$BUILD_NAME/pm2" || exit 2
exec_cmd "npm install --global --production --prefix . pm2"

# Create lisky directory and install there
exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/lisky"
cd "$SRC_DIR/$BUILD_NAME/lisky" || exit 2
exec_cmd "npm install --global --production --prefix . lisky"
cd "$SRC_DIR" || exit 2

echo "Building lisk mainnet..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$SRC_DIR/$LISK_MAIN_FILE" ]; then
	exec_cmd "wget $LISK_MAIN_URL -O $SRC_DIR/$LISK_MAIN_FILE"
fi
if [ ! -d "$SRC_DIR/$BUILD_NAME/mainnet/node_modules" ]; then
	cd "$SRC_DIR" || exit 2
	exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/mainnet && tar -xzf $LISK_MAIN_FILE -C $SRC_DIR/$BUILD_NAME/mainnet --strip-components=1"

	cd "$SRC_DIR/$BUILD_NAME/mainnet" || exit 2
	exec_cmd "npm install --production $LISK_CONFIG"
fi

echo "Building lisk testnet..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$SRC_DIR/$LISK_TEST_FILE" ]; then
	exec_cmd "wget $LISK_TEST_URL -O $SRC_DIR/$LISK_TEST_FILE"
fi
if [ ! -d "$SRC_DIR/$BUILD_NAME/testnet/node_modules" ]; then
	cd "$SRC_DIR" || exit 2
	exec_cmd "mkdir -p $SRC_DIR/$BUILD_NAME/testnet && tar -xzf $LISK_TEST_FILE -C $SRC_DIR/$BUILD_NAME/testnet --strip-components=1"

	cd "$SRC_DIR/$BUILD_NAME/testnet" || exit 2
	exec_cmd "npm install --production $LISK_CONFIG"
fi

# Change rpaths on linux
if [[ "$(uname)" == "Linux" ]]; then
	echo "Fixing rpaths (Linux)"
	echo "--------------------------------------------------------------------------"
	chrpath -d "$SRC_DIR/$BUILD_NAME/mainnet/node_modules/sodium/deps/libsodium/test/default/.libs/"*
	chrpath -d "$SRC_DIR/$BUILD_NAME/testnet/node_modules/sodium/deps/libsodium/test/default/.libs/"*
	chrpath -d "$SRC_DIR/$BUILD_NAME/lib/libreadline.so.7.0"
	chrpath -d "$SRC_DIR/$BUILD_NAME/lib/libhistory.so.7.0"
fi

echo "Stamping build..."
echo "--------------------------------------------------------------------------"
exec_cmd "echo v$(date '+%H:%M:%S %d/%m/%Y') > $SRC_DIR/$BUILD_NAME/package.build";

echo "Creating archives..."
echo "--------------------------------------------------------------------------"
# Change dir to SRC_DIR - We proceed here without full paths to finish the packaging
cd "$SRC_DIR" || exit 2

# Create $NOVER_BUILD_OUT.tar.gz - Full install
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/$NOVER_BUILD_NAME.tar.gz $BUILD_NAME"

# Set working dir to take build precompiled tar files for upgrade
cd "$SRC_DIR/$BUILD_NAME" || exit 2

# Create lisk-mainnet.tar.gz for mainnet updates
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/lisk-mainnet-$MAIN_VERSION-$OS-$ARCH.tar.gz mainnet"

# Create lisk-testnet.tar.gz for testnet updates
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/lisk-testnet-$TEST_VERSION-$OS-$ARCH.tar.gz testnet"

# Create lisky.tar.gz for updates
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/lisky-$OS-$ARCH.tar.gz lisky"

# Create pm2.tar.gz for updates
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/pm2-$OS-$ARCH.tar.gz pm2"

# Create lisk-source.tar.gz for mainnet (docker)
cd "$SRC_DIR" || exit 2 # Reset working dir
exec_cmd "mkdir -p $SRC_DIR/lisk-source"
exec_cmd "tar -xvf $SRC_DIR/$LISK_MAIN_FILE -C $SRC_DIR/lisk-source --strip-components=1"
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/lisk-source-mainnet.tar.gz lisk-source"

# Remove mainnet source temp folder for docker
exec_cmd "rm -rf $SRC_DIR/lisk-source"

# Create lisk-source.tar.gz for testnet (docker)
exec_cmd "mkdir -p $SRC_DIR/lisk-source"
exec_cmd "tar -xvf $SRC_DIR/$LISK_TEST_FILE -C $SRC_DIR/lisk-source --strip-components=1"
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/lisk-source-testnet.tar.gz lisk-source"

# Create postgresql binaries
cd "$SRC_DIR/$POSTGRESQL_DIR" || exit 2
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/$POSTGRESQL_DIR-$OS-$ARCH.tar.gz pgsql"

# Create node binaries
cd "$SRC_DIR/" || exit 2
exec_cmd "cp -rf $SRC_DIR/$NODE_DIR/compiled/ $SRC_DIR/node"
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/$NODE_DIR-$OS-$ARCH.tar.gz node"

# Create redis binaries
cd "$SRC_DIR/$REDIS_SERVER_DIR/src" || exit 2
exec_cmd "GZIP=-6 tar -czf $ROOT_DIR/release/$REDIS_SERVER_DIR-$OS-$ARCH.tar.gz $REDIS_SERVER_CLI $REDIS_SERVER_OUT"

echo "Checksumming archives..."
echo "--------------------------------------------------------------------------"
cd "$ROOT_DIR/release" || exit 2
exec_cmd "$SHA_CMD $NOVER_BUILD_NAME.tar.gz > $NOVER_BUILD_NAME.tar.gz.SHA256"
exec_cmd "$SHA_CMD lisk-source-mainnet.tar.gz > lisk-source-mainnet.tar.gz.SHA256"
exec_cmd "$SHA_CMD lisk-source-testnet.tar.gz > lisk-source-testnet.tar.gz.SHA256"
exec_cmd "$SHA_CMD lisk-mainnet-$MAIN_VERSION-$OS-$ARCH.tar.gz > lisk-mainnet-$MAIN_VERSION-$OS-$ARCH.tar.gz.SHA256"
exec_cmd "$SHA_CMD lisk-testnet-$TEST_VERSION-$OS-$ARCH.tar.gz > lisk-testnet-$TEST_VERSION-$OS-$ARCH.tar.gz.SHA256"

echo "Cleaning up..."
echo "--------------------------------------------------------------------------"
exec_cmd "rm -rf $SRC_DIR/$BUILD_NAME $SRC_DIR/$NOVER_BUILD_NAME $SRC_DIR/lisk-source*"
