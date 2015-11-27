#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. "$(pwd)/../shared.sh"

if [ ! $(uname -s) == "Linux" ]; then
  echo "Invalid operating system. Aborting."
  exit 1
fi

CMDS=("git")
check_cmds CMDS[@]

rm -rf rpi
mkdir rpi

cd rpi
exec_cmd "git clone https://github.com/raspberrypi/tools.git"
cd ..
