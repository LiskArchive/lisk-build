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
exec_cmd "rm -vrf $CRYPTI_NODE_DIR"
exec_cmd "rm -vrf $NODE_DIR"
exec_cmd "rm -vrf $SQLITE_DIR"

cd ../
