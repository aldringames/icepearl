#!/bin/bash -e
CURDIR="$(pwd)"
source ${CURDIR}/common/functions.sh
source ${CURDIR}/common/vars.sh

_msg "Deleting icepearl directory"
rm -rf $ICEPEARL_DIR
_msg "Preparing icepearl directores"
mkdir -p $ICEPEARL_DIR/{build,toolchain,sources,rootfs,iso,initrd}

# 1. binutils
_msg "Downloading binutils"
mkdir $ICEPEARL_SOURCES/binutils
_fetch https://ftp.gnu.org/pub/gnu/binutils/binutils-2.40.tar.xz $ICEPEARL_SOURCES/binutils >> $ICEPEARL_TOOLCHAIN/build-log
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

# 2. linux-headers
_msg "Downloading linux-headers"
mkdir $ICEPEARL_SOURCES/linux-headers
_fetch https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.32.tar.xz $ICEPEARL_SOURCES/linux-headers >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/linux-headers

_msg "Building linux-headers"
make ARCH=x86 mrproper >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing linux-headers"
make ARCH=x86 INSTALL_HDR_PATH="${ICEPEARL_TOOLCHAIN}/usr" headers_install >> $ICEPEARL_TOOLCHAIN/build-log

# 3. gcc-static
_msg "Downloading gcc"
mkdir $ICEPEARL_SOURCES/gcc
_fetch https://ftp.gnu.org/pub/gnu/gcc/gcc-13.1.0/gcc-13.1.0.tar.xz $ICEPEARL_SOURCES/gcc >> $ICEPEARL_TOOLCHAIN/build-log
cd $ICEPEARL_SOURCES/gcc
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64

_msg "Downloading gcc prerequisites"
./contrib/download_prerequisites

_msg "Configuring gcc-static"
mkdir $ICEPEARL_BUILD/gcc-static && cd $ICEPEARL_BUILD/gcc-static
$ICEPEARL_SOURCES/gcc/configure --prefix=$ICEPEARL_TOOLCHAIN       \
	                        --libdir=/lib                      \
	                        --libexecdir=/lib                  \
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

_msg "Building gcc-static"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing gcc-static"
_make_install >> $ICEPEARL_TOOLCHAIN/build-log

# 4. glibc
_msg "Downloading glibc"
mkdir $ICEPEARL_SOURCES/glibc
_fetch https://ftp.gnu.org/pub/gnu/glibc/glibc-2.37.tar.xz $ICEPEARL_SOURCES/glibc

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
				  --enable-kernel=4.14                           \
				  --disable-werror >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building glibc"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing glibc"
_make_install $ICEPEARL_TOOLCHAIN >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Fixing hard coded path"
sed '/RTLDLIST=/s@/usr@@g' -i $ICEPEARL_TOOLCHAIN/usr/bin/ldd

# 5. libstdc++-v3
mkdir $ICEPEARL_BUILD/libstdc++-v3 && cd $ICEPEARL_BUILD/libstdc++-v3
_msg "Configuring libstdc++-v3"
$ICEPEARL_SOURCES/gcc/libstdc++-v3/configure --prefix=/usr           \
                                             --libdir=/usr/lib       \
                                             --libexecdir=/usr/lib   \
					     --host=$ICEPEARL_TARGET \
					     --disable-libstdcxx-pch \
					     --disable-multilib      \
					     --disable-nls           \
					     --disable-werror        \
					     --with-gxx-include-dir=/$ICEPEARL_TARGET/include/c++/13.1.0 >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Building libstdc++-v3"
_make >> $ICEPEARL_TOOLCHAIN/build-log

_msg "Installing libstdc++-v3"
_make_install $ICEPEARL_TOOLCHAIN >> $ICEPEARL_TOOLCHAIN/build-log

ls $ICEPEARL_TOOLCHAIN
ls $ICEPEARL_TOOLCHAIN/*
ls $ICEPEARL_TOOLCHAIN/usr
ls $ICEPEARL_TOOLCHAIN/usr/*
