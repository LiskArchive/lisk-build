#!/bin/bash

if [ ! -z $1 ]; then
  echo "Overriding architecture with: $1"
  echo "--------------------------------------------------------------------------"
  ARCH=$1
fi

VERSION="0.2.0"
OS=`uname`
[ ! -z "$ARCH" ] || ARCH=`uname -m`
BUILD_NAME="lisk-$VERSION-$OS-$ARCH"
TARGET=""
JOBS="2"

LISK_DIR="lisk-source"
LISK_FILE="$LISK_DIR.tar.gz"
LISK_URL="http://downloads.lisk.io/$LISK_FILE"
LISK_CONFIG=""

LISK_NODE_DIR="lisk-node-0.12.13-lisk"
LISK_NODE_FILE="$LISK_NODE_DIR.zip"
LISK_NODE_URL="https://github.com/LiskHQ/lisk-node/archive/v0.12.13-lisk.tar.gz"
LISK_NODE_OUT="out/Release/node"
LISK_NODE_CONFIG=""

NODE_DIR="node-v0.12.13"
NODE_FILE="$NODE_DIR.tar.gz"
NODE_URL="https://nodejs.org/download/release/v0.12.13/$NODE_FILE"
NODE_OUT="compiled"
NODE_CONFIG=""

POSTGRESQL_DIR="postgresql-9.5.2"
POSTGRESQL_FILE="$POSTGRESQL_DIR.tar.gz"
POSTGRESQL_URL="https://ftp.postgresql.org/pub/source/v9.5.2/$POSTGRESQL_FILE"
POSTGRESQL_OUT="compiled"

NPM_CLI="$BUILD_NAME/lib/node_modules/npm/bin/npm-cli.js"

if [ $(uname -s) == "Darwin" ] || [ $(uname -s) == "FreeBSD" ]; then
  SED_OPTS="-i ''"
else
  SED_OPTS="-i"
fi

if [ "$ARCH" == "armv6l" ]; then
  export TARGET="arm-linux-gnueabihf"
  export PATH="$PATH:$(pwd)/toolchains/rpi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin"
  export CCFLAGS="-marm -march=armv6 -mfpu=vfp -mfloat-abi=hard"
  export CXXFLAGS="${CCFLAGS}"

  export GYPFLAGS="-Darmeabi=hard -Dv8_use_arm_eabi_hardfloat=true -Dv8_can_use_vfp3_instructions=false -Dv8_can_use_vfp2_instructions=true -Darm7=0 -Darm_vfp=vfp"
  export VFP3="off"
  export VFP2="on"

  LISK_CONFIG="--target_arch=arm"
  LISK_NODE_CONFIG="--without-snapshot --dest-cpu=arm --dest-os=linux --without-npm --with-arm-float-abi=hard"
  NODE_CONFIG="--without-snapshot --dest-cpu=arm --dest-os=linux --with-arm-float-abi=hard"
fi

if [ "$ARCH" == "armv7l" ]; then
  export TARGET="arm-linux-gnueabihf"
  export PATH="$(pwd)/toolchains/rpi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin:$PATH"
  export CCFLAGS="-marm -march=armv7-a -mfpu=vfp -mfloat-abi=hard"
  export CXXFLAGS="${CCFLAGS}"

  export OPENSSL_armcap=7
  export GYPFLAGS="-Darmeabi=hard -Dv8_use_arm_eabi_hardfloat=true -Dv8_can_use_vfp3_instructions=true -Dv8_can_use_vfp2_instructions=true -Darm7=1"
  export VFP3="on"
  export VFP2="on"

  LISK_CONFIG="--target_arch=arm"
  LISK_NODE_CONFIG="--without-snapshot --dest-cpu=arm --dest-os=linux --without-npm --with-arm-float-abi=hard"
  NODE_CONFIG="--without-snapshot --dest-cpu=arm --dest-os=linux --with-arm-float-abi=hard"
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
