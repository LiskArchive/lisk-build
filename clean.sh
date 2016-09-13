#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

. "$(pwd)/config.sh"
. "$(pwd)/shared.sh"

CMDS=("autoconf" "automake" "make");
check_cmds CMDS[@]

echo "Cleaning up..."
echo "--------------------------------------------------------------------------"

cd release
exec_cmd "rm -vrf lisk-*"
cd ../

mkdir -p src
cd src

exec_cmd "rm -vrf $VERSION.*"
exec_cmd "rm -vrf lisk-$VERSION-*"
exec_cmd "rm -vrf $POSTGRESQL_DIR"
exec_cmd "rm -vrf $LISK_NODE_DIR"
exec_cmd "rm -vrf $NODE_DIR"
exec_cmd "rm -vrf *.tar.gz"

cd ../
