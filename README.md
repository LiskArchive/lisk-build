# Lisk Build

A binary package building tool for [Lisk](https://lisk.io/). Allows automated compilation of binary packages, with support for multiple posix-based operating systems.

Please read [Installing Lisk (from Binaries)](https://github.com/lisk/lisk-docs/blob/master/BinaryInstall.md) if you are merely looking to install Lisk onto an already supported operating system / architecture.

## Platforms

- [Linux (native)](#linux)
  - [Linux (armv6l)](#linux-armv6-cross-compiled)
  - [Linux (armv7l)](#linux-armv7-cross-compiled)
- [Darwin (native)](#darwin)
- [FreeBSD (native)](#freebsd)

**NOTE:** For each platform, the resulting packages are placed within the `src` directory, using the following naming convention: `lisk-{version}-{os}-{architecture}.zip`.

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

- Olivier Beddows <olivier@lisk.io>

## License

MIT
