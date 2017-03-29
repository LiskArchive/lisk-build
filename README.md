# Lisk Build

A binary package building tool for [Lisk](https://lisk.io/). Allows automated compilation of binary packages, with support for multiple posix-based operating systems.

Please read [Installing Lisk (from Binaries)](https://github.com/LiskHQ/lisk-docs/blob/master/BinaryInstall.md) if you are merely looking to install Lisk onto an already supported operating system / architecture.

[![Build Status](https://travis-ci.org/LiskHQ/lisk-build.svg?branch=development)](https://travis-ci.org/LiskHQ/lisk-build)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0) 

## Platforms

- [Linux (native)](#linux)
- [Linux (armv6l)](#linux-armv6-cross-compiled)
- [Linux (armv7l)](#linux-armv7-cross-compiled)
- [Darwin (native)](#darwin)
- [FreeBSD (native)](#freebsd)

**NOTE:** For each platform, the resulting packages are placed within the `src` directory, using the following naming convention: `lisk-{version}-{os}-{architecture}.tar.gz`.

## Linux

To build a package, perform the following on a machine matching your target architecture (e.g x86_64 or i686), that has a Debian/Ubuntu based operating system installed.

1. Install `git` and `sudo`:

  ```
  sudo apt-get install git sudo
  ```

2. Clone repository:

  ```
  git clone https://github.com/LiskHQ/lisk-build.git
  ```

3. Change into `lisk-build` directory:

  ```
  cd lisk-build
  ```

4. Install build toolchain:

  ```
  bash toolchains/install_linux.sh
  ```

5. Build package:

  ```
  bash build.sh
  ```

## Linux (ARMv6) Cross Compiled

Tested devices: [Raspberry Pi 1 Model B+](https://www.raspberrypi.org/products/model-b-plus/) / [Raspberry Pi Zero](https://www.raspberrypi.org/products/pi-zero/)

Rather than compiling on the device itself, this tool caters for cross-compliation on a traditional x86 machine (e.g. on a cloud hosted VPS), allowing for much faster compilation times.

To build a package, perform the following on an x86 machine, that has a Debian/Ubuntu based operating system installed.

1. Install `git` and `sudo`:

  ```
  sudo apt-get install git sudo
  ```

2. Clone repository:

  ```
  git clone https://github.com/LiskHQ/lisk-build.git
  ```

3. Change into `lisk-build` directory:

  ```
  cd lisk-build
  ```

4. Install build toolchain:

  ```
  bash toolchains/install_linux.sh
  ```

5. Install cross-compliation toolchain:

  ```
  bash toolchains/install_rpi.sh
  ```

6. Build package:

  ```
  bash build.sh armv6l
  ```

## Linux (ARMv7) Cross Compiled

Tested devices: [Raspberry Pi 2 Model B](https://www.raspberrypi.org/products/raspberry-pi-2-model-b/) / [C.H.I.P](http://getchip.com/)

Rather than compiling on the device itself, this tool caters for cross-compliation on a traditional x86 machine (e.g. on a cloud hosted VPS), allowing for much faster compilation times.

To build a package, perform the following on an x86 machine, that has a Debian/Ubuntu based operating system installed.

1. Install `git` and `sudo`:

  ```
  sudo apt-get install git sudo
  ```

2. Clone repository:

  ```
  git clone https://github.com/LiskHQ/lisk-build.git
  ```

3. Change into `lisk-build` directory:

  ```
  cd lisk-build
  ```

4. Install build toolchain:

  ```
  bash toolchains/install_linux.sh
  ```

5. Install cross-compliation toolchain:

  ```
  bash toolchains/install_rpi.sh
  ```

6. Build package:

  ```
  bash build.sh armv7l
  ```

## Darwin

1. Install [Xcode](https://developer.apple.com/xcode/) developer tools:

  ```
  https://developer.apple.com/xcode/
  ```

2. Clone repository:

  ```
  git clone https://github.com/LiskHQ/lisk-build.git
  ```

3. Change into `lisk-build` directory:

  ```
  cd lisk-build
  ```

4. Install build toolchain:

  ```
  bash toolchains/install_darwin.sh
  ```

5. Build package:

  ```
  bash build.sh
  ```

## FreeBSD

1. Install `bash` and `git`:

  ```
  sudo pkg install -y bash git
  ```

2. Clone repository:

  ```
  git clone https://github.com/LiskHQ/lisk-build.git
  ```

3. Change into `lisk-build` directory:

  ```
  cd lisk-build
  ```

4. Install build toolchain:

  ```
  bash toolchains/install_freebsd.sh
  ```

5. Build package:

  ```
  bash build.sh
  ```

## Authors

- Isabella Dell <isabella@lightcurve.io>
- Oliver Beddows <oliver@lightcurve.io>

## License

Copyright © 2016-2017 Lisk Foundation

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the [GNU General Public License](https://github.com/LiskHQ/lisk-js/tree/master/LICENSE) along with this program.  If not, see <http://www.gnu.org/licenses/>.

***

This program also incorporates work previously released with lisk-build `0.8.0` (and earlier) versions under the [MIT License](https://opensource.org/licenses/MIT). To comply with the requirements of that license, the following permission notice, applicable to those parts of the code only, is included below:

Copyright © 2016-2017 Lisk Foundation  
Copyright © 2015 Crypti

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
