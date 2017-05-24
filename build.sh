#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

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

apply_PATCHES() {
  local PATCHES="../../patches/$OS/$ARCH/$1"
  if [ -d "$PATCHES" ]; then
    for i in "$PATCHES"/*.patch; do patch -p1 < "$i"; done
  fi
}

################################################################################

echo "Building libreadline7"
echo "--------------------------------------------------------------------------"
if [ ! -f "$LIBREADLINE_FILE" ]; then
  exec_cmd "wget $LIBREADLINE_URL -O $LIBREADLINE_FILE"
fi
if [ ! -f "$LIBREADLINE_DIR/shlib/$LIBREADLINE_OUT" ]; then
  exec_cmd "rm -rf $LIBREADLINE_DIR"
  exec_cmd "tar -zxvf $LIBREADLINE_FILE"
  cd "$LIBREADLINE_DIR" || exit 2
  exec_cmd "./configure"
  exec_cmd "make --jobs=$JOBS SHLIB_LIBS=-lcurses"
  exec_cmd "sudo make install"
  cd ../ || exit 2
fi

echo "Building postgresql..."
echo "--------------------------------------------------------------------------"
if [ ! -f "$POSTGRESQL_FILE" ]; then
  exec_cmd "wget $POSTGRESQL_URL -O $POSTGRESQL_FILE"
fi
if [ ! -f "$POSTGRESQL_DIR/$POSTGRESQL_OUT/bin/psql" ]; then
  exec_cmd "rm -rf $POSTGRESQL_DIR"
  exec_cmd "tar -zxvf $POSTGRESQL_FILE"
  cd "$POSTGRESQL_DIR" || exit 2
  exec_cmd "./configure --prefix=$(pwd)/$POSTGRESQL_OUT --with-libs=/usr/local/lib --with-includes=/usr/local/include"
  exec_cmd "make --jobs=$JOBS"
  exec_cmd "make install"
  cd ../ || exit 2
fi

echo "Building Redis-Server"
echo "--------------------------------------------------------------------------"
if [ ! -f "$REDIS_SERVER_FILE" ]; then
  exec_cmd "wget $REDIS_SERVER_URL -O $REDIS_SERVER_FILE"
fi
if [ ! -f "$REDIS_SERVER_DIR/src/$REDIS_SERVER_OUT" ]; then
  exec_cmd "rm -rf $REDIS_SERVER_DIR"
  exec_cmd "tar -zxvf $REDIS_SERVER_FILE"
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
  exec_cmd "rm -rf $BUILD_NAME"
  exec_cmd "tar -xvf $VERSION.tar.gz"
  exec_cmd "cp -Rf $VERSION $BUILD_NAME"
  exec_cmd "cp -vR $POSTGRESQL_DIR/$POSTGRESQL_OUT $BUILD_NAME/"
  exec_cmd "mkdir $BUILD_NAME/bin"
  exec_cmd "mkdir $BUILD_NAME/lib"
  exec_cmd "mkdir $BUILD_NAME/redis"
  exec_cmd "cp -vf $REDIS_SERVER_DIR/src/$REDIS_SERVER_OUT $BUILD_NAME/bin/$REDIS_SERVER_OUT"
  exec_cmd "sudo cp -v $BUILD_NAME/pgsql/lib/libpq.* /usr/lib"

  # Bundle libreadline6 and create symbolic links
  exec_cmd "cp -vf $LIBREADLINE_DIR/shlib/lib*.so.* $BUILD_NAME/lib"
  exec_cmd "cp -vf $LIBREADLINE_DIR/lib*.a $BUILD_NAME/lib"
  cd "$(pwd)/$BUILD_NAME/lib"
  exec_cmd "ln -s $LIBREADLINE_OUT libreadline.so.7"
  exec_cmd "ln -s libreadline.so.7 libreadline.so"
  exec_cmd "ln -s $LIBREADLINE_HISTORY libhistory.so.7"
  exec_cmd "ln -s libhistory.so.7 libhistory.so"
  cd ../../

  cd "$BUILD_NAME" || exit 2
  exec_cmd "npm install --production $LISK_CONFIG"

  if [[ "$(uname)" == "Linux" ]]; then
    chrpath -d "$(pwd)/node_modules/sodium/deps/libsodium/test/default/.libs/"*
  fi # Change rpaths on linux

  cd ../ || exit 2
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
  cd "$LISK_NODE_DIR" || exit 2
  apply_patches "node"
  exec_cmd "./configure --without-npm $LISK_NODE_CONFIG"
  exec_cmd "make --jobs=$JOBS"
  cd ../ || exit 2
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
  cd "$NODE_DIR" || exit 2
  apply_patches "node"
  exec_cmd "./configure --prefix=$(pwd)/compiled $NODE_CONFIG"
  exec_cmd "make --jobs=$JOBS"
  exec_cmd "make install"
  cd ../ || exit 2
fi
exec_cmd "cp -vR $NODE_DIR/$NODE_OUT/* $BUILD_NAME/"
exec_cmd "sed $SED_OPTS \"s%$(head -1 "$NPM_CLI")%#\!.\/bin\/node%g\" $NPM_CLI"

cd "$BUILD_NAME" || exit 2
# shellcheck disable=SC1090
. "$(pwd)/env.sh"
exec_cmd "npm install -g pm2"
cd ../ || exit 2

echo "Stamping build..."
echo "--------------------------------------------------------------------------"
exec_cmd "echo v$(date '+%H:%M:%S %d/%m/%Y') > $BUILD_NAME/package.build";

echo "Creating archives..."
echo "--------------------------------------------------------------------------"
# Create $BUILD_NAME.tar.gz
exec_cmd "GZIP=-6 tar -czvf ../release/$BUILD_NAME.tar.gz $BUILD_NAME"

# Create $NOVER_BUILD_NAME.tar.gz
exec_cmd "mv -f $BUILD_NAME $NOVER_BUILD_NAME"
exec_cmd "GZIP=-6 tar -czvf ../release/$NOVER_BUILD_NAME.tar.gz $NOVER_BUILD_NAME"

# Create lisk-node-$OS-$ARCH.tar.gz
cd "$NOVER_BUILD_NAME" || exit 2
exec_cmd "GZIP=-6 tar -czvf ../../release/lisk-node-$OS-$ARCH.tar.gz nodejs"
cd ../ || exit 2

# Create lisk-source.tar.gz
exec_cmd "mv -f $VERSION lisk-source"
exec_cmd "GZIP=-6 tar -czvf ../release/lisk-source.tar.gz lisk-source"

echo "Checksumming archives..."
echo "--------------------------------------------------------------------------"
cd ../release || exit 2
exec_cmd "$SHA_CMD $BUILD_NAME.tar.gz > $BUILD_NAME.tar.gz.SHA256"
exec_cmd "$SHA_CMD $NOVER_BUILD_NAME.tar.gz > $NOVER_BUILD_NAME.tar.gz.SHA256"
exec_cmd "$SHA_CMD lisk-node-$OS-$ARCH.tar.gz > lisk-node-$OS-$ARCH.tar.gz.SHA256"
exec_cmd "$SHA_CMD lisk-source.tar.gz > lisk-source.tar.gz.SHA256"
cd ../src || exit 2

echo "Cleaning up..."
echo "--------------------------------------------------------------------------"
exec_cmd "rm -rf $BUILD_NAME $NOVER_BUILD_NAME lisk-source"
cd ../ || exit 2
