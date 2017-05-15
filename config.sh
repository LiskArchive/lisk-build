#!/bin/bash
# shellcheck disable=SC2034
# Override "unused" variables. This file is used to populate build.sh.
# shellcheck disable=SC2155
# Override declare and assign variables seperately. We dont care about return values for path exports.

if [ ! -z "$1" ]; then
  echo "Overriding architecture with: $1"
  echo "--------------------------------------------------------------------------"
  ARCH="$1"
fi

VERSION="BUILD_VERSION"
OS=$(uname)
[ ! -z "$ARCH" ] || ARCH=$(uname -m)
BUILD_NAME="lisk-$VERSION-$OS-$ARCH"
NOVER_BUILD_NAME="lisk-$OS-$ARCH"
TARGET=""
JOBS="2"

LISK_DIR="$VERSION"
LISK_FILE="$VERSION.tar.gz"
LISK_NETWORK="BUILD_NETWORK"
LISK_URL="https://downloads.lisk.io/lisk/$LISK_NETWORK/$VERSION/$LISK_FILE"
LISK_CONFIG=""

LISK_NODE_DIR="lisk-node-6.10.1-lisk"
LISK_NODE_FILE="$LISK_NODE_DIR.tar.gz"
LISK_NODE_URL="https://github.com/LiskHQ/lisk-node/archive/v6.10.1-lisk.tar.gz"
LISK_NODE_OUT="out/Release/node"
LISK_NODE_CONFIG=""

NODE_DIR="node-v6.10.3"
NODE_FILE="$NODE_DIR.tar.gz"
NODE_URL="https://nodejs.org/download/release/v6.10.3/$NODE_FILE"
NODE_OUT="compiled"
NODE_CONFIG=""

POSTGRESQL_DIR="postgresql-9.6.3"
POSTGRESQL_FILE="$POSTGRESQL_DIR.tar.gz"
POSTGRESQL_URL="https://ftp.postgresql.org/pub/source/v9.6.3/$POSTGRESQL_FILE"
POSTGRESQL_OUT="pgsql"

SODIUM_DIR="libsodium-1.0.11"
SODIUM_FILE="$SODIUM_DIR.tar.gz"
SODIUM_URL="https://download.libsodium.org/libsodium/releases/$SODIUM_FILE"
SODIUM_OUT="compiled"

NODE_SODIUM_DIR="node-sodium-master"
NODE_SODIUM_FILE="$NODE_SODIUM_DIR.tar.gz"
NODE_SODIUM_URL="https://github.com/LiskHQ/node-sodium/archive/master.tar.gz"

NPM_CLI="$BUILD_NAME/lib/node_modules/npm/bin/npm-cli.js"

if [ "$(uname -s)" == "Darwin" ] || [ "$(uname -s)" == "FreeBSD" ]; then
  SED_OPTS="-i ''"
else
  SED_OPTS="-i"
fi

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
