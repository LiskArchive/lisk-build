#!/bin/bash

VERSION="0.5.3"
OS=`uname`
ARCH=`uname -m`
BUILD_NAME="crypti-$VERSION-$OS-$ARCH"

CRYPTI_DIR="crypti-linux"
CRYPTI_FILE="$CRYPTI_DIR.zip"
CRYPTI_URL="http://downloads.cryptichain.me/$CRYPTI_FILE"

CRYPTI_NODE_DIR="crypti-node-0.12.2-release"
CRYPTI_NODE_FILE="$CRYPTI_NODE_DIR.zip"
CRYPTI_NODE_URL="https://github.com/crypti/crypti-node/archive/v0.12.2-release.zip"
CRYPTI_NODE_OUT="out/Release/node"

NODE_DIR="node-v0.12.7"
NODE_FILE="$NODE_DIR.tar.gz"
NODE_URL="https://nodejs.org/download/release/v0.12.7/$NODE_FILE"
NODE_OUT="compiled/bin/node"

SQLITE_DIR="sqlite-autoconf-3090200"
SQLITE_FILE="$SQLITE_DIR.tar.gz"
SQLITE_URL="https://www.sqlite.org/2015/$SQLITE_FILE"
SQLITE_OUT="compiled/bin/sqlite3"
