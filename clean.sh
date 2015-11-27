#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

. "$(pwd)/config.sh"
. "$(pwd)/shared.sh"

CMDS=("autoconf" "automake" "make");
check_cmds CMDS[@]

echo "Cleaning up..."
echo "--------------------------------------------------------------------------"

mkdir -p src
cd src

exec_cmd "rm -vrf crypti-$VERSION-*"

if [ -d "$CRYPTI_NODE_DIR" ]; then
  exec_cmd "cd $CRYPTI_NODE_DIR; make distclean"
fi

if [ -d "$NODE_DIR" ]; then
  exec_cmd "cd $NODE_DIR; make distclean"
fi

if [ -d "$SQLITE_DIR" ]; then
  exec_cmd "cd $SQLITE_DIR; make distclean"
fi

cd ../
