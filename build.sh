#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

. "$(pwd)/config.sh"
. "$(pwd)/shared.sh"

CMDS=("autoconf" "gcc" "g++" "make" "node" "npm" "python" "tar" "unzip" "wget" "zip");
check_cmds CMDS[@]

mkdir -p src
cd src

apply_patches() {
  patches="../../patches/$(uname -s)/$1"
  if [ -d $patches ]; then
    for i in "$patches"/*.patch; do patch -p1 < $i; done
  fi
}

################################################################################

echo "Building crypti..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$CRYPTI_FILE" ]; then
  exec_cmd "wget $CRYPTI_URL -O $CRYPTI_FILE"
fi
if [ ! -d "$BUILD_NAME/node_modules" ]; then
  exec_cmd "rm -rf $BUILD_NAME"
  exec_cmd "unzip crypti-linux.zip -d $BUILD_NAME"
  cd "$BUILD_NAME"
  exec_cmd "npm install --production"
  cd ../
fi

echo "Copying scripts..."
echo "--------------------------------------------------------------------------"
exec_cmd "cp -f ../shared.sh ../scripts/* $BUILD_NAME/"

echo "Building crypti-node..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$CRYPTI_NODE_FILE" ]; then
  exec_cmd "wget $CRYPTI_NODE_URL -O $CRYPTI_NODE_FILE"
fi
if [ ! -f "$CRYPTI_NODE_DIR/$CRYPTI_NODE_OUT" ]; then
  exec_cmd "rm -rf $CRYPTI_NODE_DIR"
  exec_cmd "unzip $CRYPTI_NODE_FILE"
  cd "$CRYPTI_NODE_DIR"
  apply_patches "node"
  exec_cmd "./configure --without-npm"
  exec_cmd "make"
  cd ../
fi
exec_cmd "mkdir -p $BUILD_NAME/nodejs"
exec_cmd "cp -f $CRYPTI_NODE_DIR/$CRYPTI_NODE_OUT $BUILD_NAME/nodejs/"

echo "Building node..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$NODE_FILE" ]; then
  exec_cmd "wget $NODE_URL -O $NODE_FILE"
fi
if [ ! -f "$NODE_DIR/$NODE_OUT" ]; then
  exec_cmd "rm -rf $NODE_DIR"
  exec_cmd "tar -zxvf $NODE_FILE"
  cd "$NODE_DIR"
  apply_patches "node"
  exec_cmd "./configure --without-npm --prefix=$(pwd)/compiled"
  exec_cmd "make"
  exec_cmd "make install"
  cd ../
fi
exec_cmd "mkdir -p $BUILD_NAME/bin"
exec_cmd "cp -f $NODE_DIR/$NODE_OUT $BUILD_NAME/bin/"

echo "Building sqlite3..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$SQLITE_FILE" ]; then
  exec_cmd "wget $SQLITE_URL -O $SQLITE_FILE"
fi
if [ ! -f "$SQLITE_DIR/$SQLITE_OUT" ]; then
  exec_cmd "rm -rf $SQLITE_DIR"
  exec_cmd "tar -zxvf $SQLITE_FILE"
  cd "$SQLITE_DIR"
  exec_cmd "./configure --enable-fts5 --prefix=$(pwd)/compiled"
  exec_cmd "make"
  exec_cmd "make install"
  cd ../
fi
exec_cmd "mkdir -p $BUILD_NAME/bin"
exec_cmd "cp -f $SQLITE_DIR/$SQLITE_OUT $BUILD_NAME/bin/"

echo "Creating archive..."
echo "--------------------------------------------------------------------------"
exec_cmd "zip -qr $BUILD_NAME.zip $BUILD_NAME"
cd ../
