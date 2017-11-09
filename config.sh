#!/bin/bash
# shellcheck disable=SC2034
# Override "unused" variables. This file is used to populate build.sh.
# shellcheck disable=SC2155
# Override declare and assign variables seperately. We dont care about return values for path exports.

OS=$(uname)
[ ! -z "$ARCH" ] || ARCH=$(uname -m)
BUILD_NAME="lisk"
NOVER_BUILD_NAME="lisk-$OS-$ARCH"
TARGET=""
JOBS="2"

LISK_MAIN_DIR="$MAIN_VERSION"
LISK_MAIN_FILE="$MAIN_VERSION.tar.gz"
LISK_MAIN_URL="https://downloads.lisk.io/lisk/main/$MAIN_VERSION/$LISK_MAIN_FILE"
LISK_MAIN_CONFIG=""

LISK_TEST_DIR="$TEST_VERSION"
LISK_TEST_FILE="$TEST_VERSION.tar.gz"
LISK_TEST_URL="https://downloads.lisk.io/lisk/test/$TEST_VERSION/$LISK_TEST_FILE"
LISK_TEST_CONFIG=""

NODE_VERSION="v6.11.2"
NODE_DIR="node-$NODE_VERSION"
NODE_FILE="$NODE_DIR.tar.gz"
NODE_URL="https://nodejs.org/download/release/v6.11.2/$NODE_FILE"
NODE_OUT="compiled"
NODE_CONFIG=""

POSTGRESQL_VERSION="9.6.4"
POSTGRESQL_DIR="postgresql-$POSTGRESQL_VERSION"
POSTGRESQL_FILE="$POSTGRESQL_DIR.tar.gz"
POSTGRESQL_URL="https://ftp.postgresql.org/pub/source/v9.6.4/$POSTGRESQL_FILE"
POSTGRESQL_OUT="pgsql"

SODIUM_DIR="libsodium-1.0.11"
SODIUM_FILE="$SODIUM_DIR.tar.gz"
SODIUM_URL="https://download.libsodium.org/libsodium/releases/$SODIUM_FILE"
SODIUM_OUT="compiled"

NODE_SODIUM_DIR="node-sodium-master"
NODE_SODIUM_FILE="$NODE_SODIUM_DIR.tar.gz"
NODE_SODIUM_URL="https://github.com/LiskHQ/node-sodium/archive/master.tar.gz"

REDIS_SERVER_VERSION="3.2.9"
REDIS_SERVER_DIR="redis-$REDIS_SERVER_VERSION"
REDIS_SERVER_FILE="$REDIS_SERVER_DIR.tar.gz"
REDIS_SERVER_URL="http://download.redis.io/releases/$REDIS_SERVER_FILE"
REDIS_SERVER_OUT="redis-server"
REDIS_SERVER_CLI="redis-cli"
REDIS_SERVER_CONFIG=""

LIBREADLINE_DIR="readline-master"
LIBREADLINE_FILE="$LIBREADLINE_DIR.tar.gz"
LIBREADLINE_URL="http://git.savannah.gnu.org/cgit/readline.git/snapshot/$LIBREADLINE_FILE"
LIBREADLINE_OUT="libreadline.so.7.0"
LIBREADLINE_HISTORY="libhistory.so.7.3"

JQ_VERSION="1.5"
JQ_DIR="jq-$JQ_VERSION"
JQ_FILE="$JQ_DIR.tar.gz"
JQ_URL="https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/$JQ_FILE"
JQ_OUT="jq"

NPM_CLI="lib/node_modules/npm/bin/npm-cli.js"

if [ "$(uname -s)" == "Darwin" ]; then
	SHA_CMD="shasum -a 256"
else
	SHA_CMD="sha256sum"
fi

if [ "$TARGET" != "" ]; then
	export CC="${TARGET}-gcc"
	export CXX="${TARGET}-g++"
	export AR="${TARGET}-ar"
	export RANLIB="${TARGET}-ranlib"
	export LD="${TARGET}-ld"
	export CPP="${TARGET}-gcc -E"
	export STRIP="${TARGET}-strip"
	export OBJCOPY="${TARGET}-objcopy"
	export OBJDUMP="${TARGET}-objdump"
	export NM="${TARGET}-nm"
	export AS="${TARGET}-as"
fi
