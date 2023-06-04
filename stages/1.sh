#!/bin/bash -e
CURDIR="$(pwd)"
source ${CURDIR}/common/functions.sh                                                                 source ${CURDIR}/common/vars.sh

_msg "Dwleting icepearl directory"
rm -rf $ICEPEARL_DIR
_msg "Preparing icepearl directores"
mkdir -p $ICEPEARL_DIR/{build,toolchain,sources,rootfs,iso,initrd}

_msg "Cloning binutils"
_git_clone master git://sourceware.org/git/binutils-gdb.git $ICEPEARL_SOURCES/binutils >> $ICEPEARL_ISO/build-log
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
				     --disable-multilib                 \
				     --disable-nls                      \
				     --disable-werror >> $ICEPEARL_ISO/build-log

_msg "Building binutils"
_make >> $ICEPEARL_ISO/build-log

_msg "Installing binutils"
_make_install >> $ICEPEARL_ISO/build-log
