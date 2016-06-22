#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

. "$(pwd)/shared.sh"
. "$(pwd)/config.sh"

CMDS=("autoconf" "gcc" "g++" "make" "node" "npm" "python" "tar" "wget");
check_cmds CMDS[@]

mkdir -p src
cd src

apply_patches() {
  local patches="../../patches/$OS/$ARCH/$1"
  if [ -d $patches ]; then
    for i in "$patches"/*.patch; do patch -p1 < $i; done
  fi
}

################################################################################

echo "Building postgresql..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$POSTGRESQL_FILE" ]; then
  exec_cmd "wget $POSTGRESQL_URL -O $POSTGRESQL_FILE"
fi
if [ ! -f "$POSTGRESQL_DIR/$POSTGRESQL_OUT/bin/psql" ]; then
  exec_cmd "rm -rf $POSTGRESQL_DIR"
  exec_cmd "tar -zxvf $POSTGRESQL_FILE"
  cd "$POSTGRESQL_DIR"
  exec_cmd "./configure --prefix=$(pwd)/$POSTGRESQL_OUT $POSTGRESQL_CONFIG"
  exec_cmd "make --jobs=$JOBS"
  exec_cmd "make install"
  cd ../
fi

echo "Building lisk..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$LISK_FILE" ]; then
  exec_cmd "wget $LISK_URL -O $LISK_FILE"
fi
if [ ! -d "$BUILD_NAME/node_modules" ]; then
  exec_cmd "rm -rf $BUILD_NAME"
  exec_cmd "tar -xvf $VERSION.tar.gz"
  exec_cmd "cp -Rf $VERSION $BUILD_NAME"
  exec_cmd "cp -vR $POSTGRESQL_DIR/$POSTGRESQL_OUT $BUILD_NAME/"
  exec_cmd "sudo cp -v $BUILD_NAME/pgsql/lib/libpq.* /usr/lib"
  cd "$BUILD_NAME"
  exec_cmd "npm install --production $LISK_CONFIG"
  cd ../
fi

echo "Copying scripts..."
echo "--------------------------------------------------------------------------"
exec_cmd "cp -f ../shared.sh ../scripts/* $BUILD_NAME/"
exec_cmd "cp -fR ../etc $BUILD_NAME/"

echo "Building lisk-node..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$LISK_NODE_FILE" ]; then
  exec_cmd "wget $LISK_NODE_URL -O $LISK_NODE_FILE"
fi
if [ ! -f "$LISK_NODE_DIR/$LISK_NODE_OUT" ]; then
  exec_cmd "rm -rf $LISK_NODE_DIR"
  exec_cmd "tar -zxvf $LISK_NODE_FILE"
  cd "$LISK_NODE_DIR"
  apply_patches "node"
  exec_cmd "./configure --without-npm $LISK_NODE_CONFIG"
  exec_cmd "make --jobs=$JOBS"
  cd ../
fi
exec_cmd "mkdir -p $BUILD_NAME/nodejs"
exec_cmd "cp -f $LISK_NODE_DIR/$LISK_NODE_OUT $BUILD_NAME/nodejs/"

echo "Building node..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$NODE_FILE" ]; then
  exec_cmd "wget $NODE_URL -O $NODE_FILE"
fi
if [ ! -f "$NODE_DIR/$NODE_OUT/bin/node" ] || [ ! -f "$NODE_DIR/$NODE_OUT/bin/npm" ]; then
  exec_cmd "rm -rf $NODE_DIR"
  exec_cmd "tar -zxvf $NODE_FILE"
  cd "$NODE_DIR"
  apply_patches "node"
  exec_cmd "./configure --prefix=$(pwd)/compiled $NODE_CONFIG"
  exec_cmd "make --jobs=$JOBS"
  exec_cmd "make install"
  cd ../
fi
exec_cmd "mkdir -p $BUILD_NAME/bin"
exec_cmd "cp -vR $NODE_DIR/$NODE_OUT/* $BUILD_NAME/"
exec_cmd "sed $SED_OPTS \"s%$(head -1 $NPM_CLI)%#\!.\/bin\/node%g\" $NPM_CLI"

cd "$BUILD_NAME"
exec_cmd "npm install forever"
exec_cmd "rm -f bin/forever"
exec_cmd "ln -s ../node_modules/forever/bin/forever bin/forever"
cd ../

echo "Stamping build..."
echo "--------------------------------------------------------------------------"
exec_cmd "echo v`date '+%H:%M:%S %d/%m/%Y'` > $BUILD_NAME/package.build";

echo "Creating archives..."
echo "--------------------------------------------------------------------------"
# Create $BUILD_NAME.tar.gz
exec_cmd "GZIP=-6 tar -czvf ../release/$BUILD_NAME.tar.gz $BUILD_NAME"

# Create $NOVER_BUILD_NAME.tar.gz
exec_cmd "mv -f $BUILD_NAME $NOVER_BUILD_NAME"
exec_cmd "GZIP=-6 tar -czvf ../release/$NOVER_BUILD_NAME.tar.gz $NOVER_BUILD_NAME"

# Create lisk-node-$OS-$ARCH.tar.gz
cd "$NOVER_BUILD_NAME"
exec_cmd "GZIP=-6 tar -czvf ../../release/lisk-node-$OS-$ARCH.tar.gz nodejs"
cd ../

# Create lisk-source.tar.gz
exec_cmd "mv -f $VERSION lisk-source"
exec_cmd "GZIP=-6 tar -czvf ../release/lisk-source.tar.gz lisk-source"

echo "Checksumming archives..."
echo "--------------------------------------------------------------------------"
cd ../release
exec_cmd "$MD5_CMD $BUILD_NAME.tar.gz > $BUILD_NAME.tar.gz.md5"
exec_cmd "$MD5_CMD $NOVER_BUILD_NAME.tar.gz > $NOVER_BUILD_NAME.tar.gz.md5"
exec_cmd "$MD5_CMD lisk-node-$OS-$ARCH.tar.gz > lisk-node-$OS-$ARCH.tar.gz.md5"
exec_cmd "$MD5_CMD lisk-source.tar.gz > lisk-source.tar.gz.md5"
cd ../src

echo "Cleaning up..."
echo "--------------------------------------------------------------------------"
exec_cmd "rm -rf $BUILD_NAME $NOVER_BUILD_NAME lisk-source"
cd ../
