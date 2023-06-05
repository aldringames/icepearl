#!/bin/bash -e
CURDIR="$(pwd)"
source ${CURDIR}/common/functions.sh
source ${CURDIR}/common/vars.sh

_msg "Deleting icepearl directory"
rm -rf $ICEPEARL_DIR
_msg "Preparing icepearl directores"
mkdir -p $ICEPEARL_DIR/{build,toolchain,sources,rootfs,iso,initrd}

# 1. binutils
_msg "Cloning binutils"
_clone master git://sourceware.org/git/binutils-gdb.git $ICEPEARL_SOURCES/binutils >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/binutils
sed '6009s/$add_dir//' -i ltmain.sh

_msg "Configuring binutils"
mkdir $ICEPEARL_BUILD/binutils && cd $ICEPEARL_BUILD/binutils
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
				     --disable-nls                      \
				     --disable-werror >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building binutils"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing binutils"
_make_install >> $ICEPEARL_TOOLCHAIN/build-log

# 2. linux-headers
_msg "Cloning linux-headers"
_clone linux-rolling-lts git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git $ICEPEARL_SOURCES/linux-headers
cd $ICEPEARL_SOURCES/linux-headers

_msg "Building linux-headers"
make ARCH=x86 mrproper >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing linux-headers"
make ARCH=x86 INSTALL_HDR_PATH="${ICEPEARL_TOOLCHAIN}/usr" headers_install >> $ICEPEARL_TOOLCHAIN/build-log

ls $ICEPEARL_TOOLCHAIN
ls $ICEPEARL_TOOLCHAIN/*
ls $ICEPEARL_TOOLCHAIN/usr
ls $ICEPEARL_TOOLCHAIN/usr/*
