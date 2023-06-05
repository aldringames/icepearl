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
_clone linux-rolling-lts git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git $ICEPEARL_SOURCES/linux-headers >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/linux-headers

_msg "Building linux-headers"
make ARCH=x86 mrproper >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing linux-headers"
make ARCH=x86 INSTALL_HDR_PATH="${ICEPEARL_TOOLCHAIN}/usr" headers_install >> $ICEPEARL_TOOLCHAIN/build-log

# 3. gcc-static
_msg "Cloning gcc"
_clone releases/gcc-13 git://gcc.gnu.org/git/gcc.git $ICEPEARL_SOURCES/gcc >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/gcc
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64

_msg "Configuring gcc-static"
mkdir $ICEPEARL_BUILD/gcc-static && cd $ICEPEARL_BUILD/gcc-static
$ICEPEARL_SOURCES/gcc/configure --prefix=$ICEPEARL_TOOLCHAIN       \
	                        --libexecdir=/lib                  \
                                --target=$ICEPEARL_TARGET          \
				--with-sysroot=$ICEPEARL_TOOLCHAIN \
				--with-newlib                      \
				--without-headers                  \
				--enable-initfini-array            \
				--enable-languages=c,c++           \
				--disable-libatomic                \
				--disable-libgomp                  \
				--disable-libquadmath              \
				--disable-libssp                   \
				--disable-libstdcxx                \
				--disable-libvtv                   \
				--disable-nls                      \
				--disable-shared                   \
                                --disable-threads >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building gcc-static"
_make all-gcc all-target-libgcc> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing gcc-static"
make install-gcc install-target-libgcc >> $ICEPEARL_TOOLCHAIN/build-log

# 4. glibc
_msg "Cloning glibc"
_clone master git://sourceware.org/git/glibc.git $ICEPEARL_SOURCES/glibc >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Configuring glibc"
mkdir $ICEPEARL_BUILD/glibc && cd $ICEPEARL_BUILD/glibc
cat > configparms <<EOF
slibdir=/usr/lib
rtlddir=/usr/lib
sbindir=/usr/bin
rootsbindir=/usr/bin
EOF
$ICEPEARL_SOURCES/glibc/configure --prefix=/usr                                  \
	                          --libdir=/usr/lib                              \
				  --libexecdir=/usr/lib                          \
				  --host=$ICEPEARL_TARGET                        \
				  --with-headers=$ICEPEARL_TOOLCHAIN/usr/include \
				  --enable-kernel=4.19 >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building glibc"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing binutils"
_make_install $ICEPEARL_TOOLCHAIN >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Fixing hard coded path"
sed '/RTLDLIST=/s@/usr@@g' -i $ICEPEARL_TOOLCHAIN/usr/bin/ldd

ls $ICEPEARL_TOOLCHAIN
ls $ICEPEARL_TOOLCHAIN/*
ls $ICEPEARL_TOOLCHAIN/usr
ls $ICEPEARL_TOOLCHAIN/usr/*
