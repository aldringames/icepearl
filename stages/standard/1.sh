#!/bin/bash -e
CURDIR="$(pwd)"

source "${CURDIR}/common/functions.sh"
source "${CURDIR}/common/vars.sh"

_msg "Preparing icepearl directories"
mkdir -p $ICEPEARL_DIR/{build,toolchain,sources,rootfs,iso}

_msg "Cloning binutils"
_clone master git://sourceware.org/git/binutils-gdb.git $ICEPEARL_SOURCES/binutils
cd $ICEPEARL_SOURCES/binutils
_msg "Using a sysroot support for binutils"
sed '6009s/$add_dir//' -i ltmain.sh

mkdir $ICEPEARL_BUILD/binutils && cd $ICEPEARL_BUILD/binutils
_msg "Configuring binutils"
AR=$BLD_AR \
AS=$BLD_AS \
CC=$BLD_CC \
CXX=$BLD_CXX \
CFLAGS=$BLD_CFLAGS \
CXXFLAGS=$BLD_CXXFLAGS \
LDFLAGS=$BLD_LDFLAGS \
$ICEPEARL_SOURCES/binutils/configure --prefix=$ICEPEARL_TOOLCHAIN       \
	                             --build=$ICEPEARL_HOST             \
	                             --host=$ICEPEARL_HOST              \
				     --target=$ICEPEARL_TARGET          \
				     --with-sysroot=$ICEPEARL_TOOLCHAIN \
				     --enable-deterministic-archives    \
				     --disable-gdb                      \
				     --disable-gdbserver                \
				     --disable-gdbsupport               \
				     --disable-gprof                    \
				     --disable-gprofng                  \
				     --disable-multilib                 \
				     --disable-nls                      \
				     --disable-werror > /dev/null

_msg "Building binutils"
make -j4 > /dev/null

_msg "Installing binutils"
make install > /dev/null
