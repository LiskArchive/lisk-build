#!/bin/bash

VERSION="0.5.3"
OS=`uname`
[ ! -z "$ARCH" ] || ARCH=`uname -m`
BUILD_NAME="crypti-$VERSION-$OS-$ARCH"
TARGET=""

CRYPTI_DIR="crypti-linux"
CRYPTI_FILE="$CRYPTI_DIR.zip"
CRYPTI_URL="http://downloads.cryptichain.me/$CRYPTI_FILE"
CRYPTI_CONFIG=""

CRYPTI_NODE_DIR="crypti-node-0.12.2-release"
CRYPTI_NODE_FILE="$CRYPTI_NODE_DIR.zip"
CRYPTI_NODE_URL="https://github.com/crypti/crypti-node/archive/v0.12.2-release.zip"
CRYPTI_NODE_OUT="out/Release/node"
CRYPTI_NODE_CONFIG=""

NODE_DIR="node-v0.12.7"
NODE_FILE="$NODE_DIR.tar.gz"
NODE_URL="https://nodejs.org/download/release/v0.12.7/$NODE_FILE"
NODE_OUT="compiled/bin/node"
NODE_CONFIG=""

SQLITE_DIR="sqlite-autoconf-3090200"
SQLITE_FILE="$SQLITE_DIR.tar.gz"
SQLITE_URL="https://www.sqlite.org/2015/$SQLITE_FILE"
SQLITE_OUT="compiled/bin/sqlite3"
SQLITE_CONFIG=""

if [ "$TARGET" != "" ]; then
  export CC="${CROSS_COMPILER}-gcc"
  export CXX="${CROSS_COMPILER}-g++"
  export AR="${CROSS_COMPILER}-ar"
  export RANLIB="${CROSS_COMPILER}-ranlib"
  export LD="${CROSS_COMPILER}-ld"
  export CPP="${CROSS_COMPILER}-gcc -E"
  export STRIP="${CROSS_COMPILER}-strip"
  export OBJCOPY="${CROSS_COMPILER}-objcopy"
  export OBJDUMP="${CROSS_COMPILER}-objdump"
  export NM="${CROSS_COMPILER}-nm"
  export AS="${CROSS_COMPILER}-as"
fi
