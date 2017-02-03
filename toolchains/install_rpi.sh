#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2
# shellcheck disable=SC1090
. "$(pwd)/../shared.sh"

if [ ! "$(uname -s)" == "Linux" ]; then
  echo "Invalid operating system. Aborting."
  exit 1
fi

# shellcheck disable=SC2034
# Ignoring the failure due to shell indirection
CMDS=("git")
check_cmds CMDS[@]

rm -rf rpi
mkdir rpi

# Shellchecks suggested solution brings more issues, we will just override the issue instead since this is the expected behavior.
# shellcheck disable=SC2103
cd rpi || exit 2
exec_cmd "git clone https://github.com/raspberrypi/tools.git"
cd .. || exit 2
