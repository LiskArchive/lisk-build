#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

# We dont care about return code here
# shellcheck disable=SC2155
export PATH="$(pwd)/bin:$(pwd)/pgsql/bin:$PATH"
# We dont care about return code here
# shellcheck disable=SC2155
export LD_LIBRARY_PATH="$(pwd)/pgsql/lib:$LD_LIBRARY_PATH"

# Detect if lisk run under security system account to fake home dir to fix security issue with pm2 
if ! [[ -d "/home/$USER" ]];then 
	export HOME="$(pwd)/home"
fi
