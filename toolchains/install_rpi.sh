#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2
. "$(pwd)/../shared.sh"

if [ ! "$(uname -s)" == "Linux" ]; then
  echo "Invalid operating system. Aborting."
  exit 1
fi

# shellcheck disable=SC2034
# ignoring the failure due to shell indirection
CMDS=("git")
check_cmds CMDS[@]

rm -rf rpi
mkdir rpi

for DIR in rpi/
do 
cd $DIR || exit 2
exec_cmd "git clone https://github.com/raspberrypi/tools.git"
cd .. || exit 2
done
