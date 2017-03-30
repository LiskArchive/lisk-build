#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2
# shellcheck disable=SC1090
. "$(pwd)/../shared.sh"

if [ ! "$(uname -s)" == "FreeBSD" ]; then
  echo "Invalid operating system. Aborting."
  exit 1
fi

sudo pkg install -y autoconf automake curl gcc git gmake libtool node6 npm3 postgresql96-server postgresql96-contrib python security/ca_root_nss wget unzip

if [ ! -e "/usr/local/bin/make" ] && [ -e "/usr/bin/make" ]; then
  sudo mv /usr/bin/make /usr/bin/make.moved
  sudo ln -s /usr/local/bin/gmake /usr/local/bin/make
fi

if [ ! -e "/usr/local/bin/gcc" ] && [ -e "/usr/local/bin/gcc48" ]; then
  sudo ln -s /usr/local/bin/gcc48 /usr/local/bin/gcc
fi

if [ ! -e "/usr/local/bin/g++" ] && [ -e "/usr/local/bin/g++48" ]; then
  sudo ln -s /usr/local/bin/g++48 /usr/local/bin/g++
fi
