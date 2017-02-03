#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

# shellcheck source=./shared.sh
. "$(pwd)/shared.sh"
# shellcheck source=./config.sh
. "$(pwd)/config.sh"

# shellcheck disable=SC2034
# ignoring the failure due to shell indirection
CMDS=("autoconf" "automake" "make");
check_cmds CMDS[@]

echo "Cleaning up..."
echo "--------------------------------------------------------------------------"

cd release || exit 2
exec_cmd "rm -vrf lisk-*"
cd ../ || exit 2

mkdir -p src
cd src || exit 2

exec_cmd "rm -vrf $VERSION.*"
exec_cmd "rm -vrf lisk-$VERSION-*"

if [ "$1" = "all" ]; then
  exec_cmd "rm -vrf $SODIUM_DIR"
  exec_cmd "rm -vrf $NODE_SODIUM_DIR"
  exec_cmd "rm -vrf $POSTGRESQL_DIR"
  exec_cmd "rm -vrf $LISK_NODE_DIR"
  exec_cmd "rm -vrf $NODE_DIR"
  exec_cmd "rm -vrf *.tar.gz"
fi

cd ../ || exit 2
