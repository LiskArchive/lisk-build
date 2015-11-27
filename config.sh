#!/bin/bash

if [ ! -z $1 ]; then
  echo "Overriding architecture with: $1"
  echo "--------------------------------------------------------------------------"
  ARCH=$1
fi

VERSION="0.5.3"
OS=`uname`
[ ! -z "$ARCH" ] || ARCH=`uname -m`
BUILD_NAME="crypti-$VERSION-$OS-$ARCH"
TARGET=""
JOBS="2"

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

if [ "$ARCH" == "armv6l" ]; then
  export TARGET="arm-linux-gnueabihf"
  export PATH="$PATH:$(pwd)/toolchains/rpi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin"
  export CCFLAGS="-marm -march=armv6 -mfpu=vfp -mfloat-abi=hard"
  export CXXFLAGS="${CCFLAGS}"

  export GYPFLAGS="-Darmeabi=hard -Dv8_use_arm_eabi_hardfloat=true -Dv8_can_use_vfp3_instructions=false -Dv8_can_use_vfp2_instructions=true -Darm7=0 -Darm_vfp=vfp"
  export VFP3="off"
  export VFP2="on"

  CRYPTI_CONFIG="--target_arch=arm"
  CRYPTI_NODE_CONFIG="--without-snapshot --dest-cpu=arm --dest-os=linux --without-npm --with-arm-float-abi=hard"
  NODE_CONFIG="${CRYPTI_NODE_CONFIG}"
  SQLITE_CONFIG="--host=arm"
fi

if [ "$ARCH" == "armv7-a" ]; then
  export TARGET="arm-linux-gnueabihf"
  export PATH="$(pwd)/toolchains/rpi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin:$PATH"
  export CCFLAGS="-marm -march=armv7-a -mfpu=vfp -mfloat-abi=hard"
  export CXXFLAGS="${CCFLAGS}"

  export OPENSSL_armcap=7
  export GYPFLAGS="-Darmeabi=hard -Dv8_use_arm_eabi_hardfloat=true -Dv8_can_use_vfp3_instructions=true -Dv8_can_use_vfp2_instructions=true -Darm7=1"
  export VFP3="on"
  export VFP2="on"

  CRYPTI_CONFIG="--target_arch=arm"
  CRYPTI_NODE_CONFIG="--without-snapshot --dest-cpu=arm --dest-os=linux --without-npm --with-arm-float-abi=hard"
  NODE_CONFIG="${CRYPTI_NODE_CONFIG}"
  SQLITE_CONFIG="--host=arm"
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
