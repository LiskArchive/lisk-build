#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

# Binary paths
export PATH="$PWD/bin:$PWD/pgsql/bin:$PWD/node/bin:$PWD/lisky/bin:$PWD/pm2/bin$PATH"

# Load dynamic libaries paths
export LD_LIBRARY_PATH="$PWD/pgsql/lib:$PWD/lib:$PWD/node/lib:$LD_LIBRARY_PATH"

# PM2 home directory
export PM2_HOME="$PWD/.pm2"

# Node libraries path
export NODE_PATH="$PWD/node/lib"
