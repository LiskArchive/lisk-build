#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

# We dont care about return code here
# shellcheck disable=SC2155
export PATH="$(pwd)/bin:$(pwd)/pgsql/bin:$(pwd)/node/bin:$PATH"
# We dont care about return code here
# shellcheck disable=SC2155
export LD_LIBRARY_PATH="$(pwd)/pgsql/lib:$(pwd)/lib:$(pwd)/node/lib:$LD_LIBRARY_PATH"
# We dont care about return code here
# shellcheck disable=SC2155
export PM2_HOME="$(pwd)/.pm2"
# Node Path
export NODE_PATH="$(pwd)/node/lib"
