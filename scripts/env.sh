#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

#shellcheck disable=SC2155
#We dont care about return code here
export PATH="$(pwd)/bin:$(pwd)/pgsql/bin:$PATH"
export LD_LIBRARY_PATH="$(pwd)/pgsql/lib:$LD_LIBRARY_PATH"
