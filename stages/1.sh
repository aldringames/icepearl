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
mkdir $ICEPEARL_SOURCES/binutils
_clone master git://sourceware.org/git/binutils-gdb.git $ICEPEARL_SOURCES/binutils >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/binutils
sed '6009s/$add_dir//' -i ltmain.sh

_msg "Configuring binutils"
mkdir $ICEPEARL_BUILD/binutils && cd $ICEPEARL_BUILD/binutils
$ICEPEARL_SOURCES/binutils/configure --prefix=$ICEPEARL_TOOLCHAIN       \
	                             --target=$ICEPEARL_TARGET          \
				     --with-sysroot=$ICEPEARL_TOOLCHAIN \
				     --disable-multilib                 \
				     --disable-nls                      \
				     --disable-werror >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building binutils"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing binutils"
_make_install >> $ICEPEARL_TOOLCHAIN/build-log

# 2. gcc
_msg "Cloning gcc"
_clone Thesis git://gcc.gnu.org/git/gcc.git $ICEPEARL_SOURCES/gcc >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/gcc
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64

_msg "Downloading gcc prerequisites"
./contrib/download_prerequisites

_msg "Configuring gcc"
mkdir $ICEPEARL_BUILD/gcc-static && cd $ICEPEARL_BUILD/gcc-static
$ICEPEARL_SOURCES/gcc/configure --prefix=$ICEPEARL_TOOLCHAIN       \
	                        --target=$ICEPEARL_TARGET          \
				--with-sysroot=$ICEPEARL_TOOLCHAIN \
				--with-newlib                      \
				--without-headers                  \
				--enable-default-pie               \
				--enable-default-ssp               \
				--enable-languages=c,c++           \
				--disable-libatomic                \
				--disable-libgomp                  \
				--disable-libquadmath              \
				--disable-libssp                   \
				--disable-libstdcxx                \
				--disable-libvtv                   \
				--disable-multilib                 \
				--disable-nls                      \
				--disable-shared                   \
				--disable-threads                  \
                                --disable-werror >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building gcc"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing gcc"
_make_install >> $ICEPEARL_TOOLCHAIN/build-log

# 3. linux-headers
_msg "Cloning linux-headers"
_clone linux-rolling-lts git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git $ICEPEARL_SOURCES/linux-headers >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/linux-headers

_msg "Building linux-headers"
make mrproper

_msg "Installing linux-headers"
make INSTALL_HDR_PATH=$ICEPEARL_TOOLCHAIN/usr headers_install

# 4. glibc
_msg "Cloning glibc"
_clone master git://sourceware.org/git/glibc.git $ICEPEARL_SOURCES/glibc >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Configuring glibc"
mkdir $ICEPEARL_BUILD/glibc && cd $ICEPEARL_BUILD/glibc
cat > configparms <<EOF
slibdir=/usr/lib
rootsbindir=/usr/sbin
EOF
$ICEPEARL_SOURCES/glibc/configure --prefix=/usr                                  \
	                          --host=$ICEPEARL_TARGET                        \
				  --with-headers=$ICEPEARL_TOOLCHAIN/usr/include \
				  --enable-kernel=4.14                           \
				  --disable-werror >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building glibc"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing glibc"
_make_install $ICEPEARL_TOOLCHAIN >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Fixing hard coded path"
sed '/RTLDLIST=/s@/usr@@g' -i $ICEPEARL_TOOLCHAIN/usr/bin/ldd

# 5. libstdcpp
mkdir $ICEPEARL_BUILD/libstdcpp && cd $ICEPEARL_BUILD/libstdcpp
_msg "Configuring libstdc++-v3"
$ICEPEARL_SOURCES/gcc/libstdc++-v3/configure --prefix=/usr           \
                                             --host=$ICEPEARL_TARGET \
					     --disable-libstdcxx-pch \
					     --disable-multilib      \
					     --disable-nls           \
					     --disable-werror >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building libstdc++-v3"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing libstdc++-v3"
_make_install $ICEPEARL_TOOLCHAIN >> $ICEPEARL_TOOLCHAIN/build-log

ls $ICEPEARL_TOOLCHAIN
ls $ICEPEARL_TOOLCHAIN/*
ls $ICEPEARL_TOOLCHAIN/usr
ls $ICEPEARL_TOOLCHAIN/usr/*
