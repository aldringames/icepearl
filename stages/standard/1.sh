#!/bin/bash -e
CURDIR="$(pwd)"

source "${CURDIR}/common/functions.sh"
source "${CURDIR}/common/vars.sh"

_msg "Preparing icepearl directories"
mkdir -p $ICEPEARL_DIR/{build,toolchain,sources,rootfs,iso}
_msg "Adding Icepearl's toolchain bin to the PATH"
export PATH="$ICEPEARL_TOOLCHAIN/bin:$PATH"

# 1. binutils
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
				     --with-sysroot=/                   \
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

# 2. gcc (compiler and libgcc)
_msg "Cloning gcc"
_clone Thesis git://gcc.gnu.org/git/gcc.git $ICEPEARL_SOURCES/gcc
cd $ICEPEARL_SOURCES/gcc
case $ICEPEARL_TARGET in
	aarch64-icepearl-linux-gnu)
		sed -e '/mabi.lp64=/s/lib64/lib/' -i.orig gcc/config/i386/t-aarch64-linux
		;;
	mips64-icepearl-linux-gnu)
		;;
	riscv64-icepearl-linux-gnu)
		;;
	x86_64-icepearl-linux-gnu)
		sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
		;;
esac

case $ICEPEARL_TARGET in
	aarch64-icepearl-linux-gnu)
		_gcc_opts="--enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419" ;;
	mips64-icepearl-linux-gnu)
		_gcc_opts="--with-endian=big --with-arch=mips64r2 --with-float=hard" ;;
	riscv64-icepearl-linux-gnu)
		_gcc_opts="--with-arch=rv64gc --with-abi=lp64d" ;;
	x86_64-icepearl-linux-gnu)
		_gcc_opts="--with-arch=x86-64 --with-tune=generic" ;;
esac
mkdir $ICEPEARL_BUILD/gcc && cd $ICEPEARL_BUILD/gcc
_msg "Configuring gcc"
AR=$BLD_AR \
CC=$BLD_CC \
CXX=$BLD_CXX \
CFLAGS=$BLD_CFLAGS \
CXXFLAGS=$BLD_CXXFLAGS \
LDFLAGS=$BLD_LDFLAGS \
$ICEPEARL_SOURCES/gcc/configure --prefix=$ICEPEARL_TOOLCHAIN \
                                --libdir=/usr/lib            \
				--libexecdir=/usr/lib        \
                                --build=$ICEPEARL_HOST       \
				--host=$ICEPEARL_HOST        \
                                --target=$ICEPEARL_TARGET    \
				--with-newlib                \
                                --with-sysroot=/             \
				--without-headers            \
				--enable-initfini-array      \
				--enable-languages=c,c++     \
				--disable-multilib           \
				--disable-nls                \
				--disable-werror $_gcc_opts > /dev/null

_msg "Building gcc (compiler and libgcc)"
make -j4 all-gcc all-target-libgcc > /dev/null

_msg "Installing gcc (compiler and libgcc)"
make install-gcc install-target-libgcc > /dev/null

ls $ICEPEARL_TOOLCHAIN
ls $ICEPEARL_TOOLCHAIN/$ICEPEARL_TARGET
ls $ICEPEARL_TOOLCHAIN/$ICEPEARL_TARGET/include
ls $ICEPEARL_TOOLCHAIN/$ICEPEARL_TARGET/include/c++
$ICEPEARL_TARGET-gcc --version

# 4. glibc
_msg "Cloning glibc"
_clone master git://sourceware.org/git/glibc.git $ICEPEARL_SOURCES/glibc

mkdir $ICEPEARL_BUILD/glibc && cd $ICEPEARL_BUILD/glibc
_msg "Configuring glibc"
cat > configparms <<EOF
slibdir=/usr/lib
rtlddir=/usr/lib
sbindir=/usr/bin
rootsbindir=/usr/bin
EOF
$ICEPEARL_SOURCES/glibc/configure --prefix=/usr           \
                                  --libdir=/usr/lib       \
				  --libexecdir=/usr/lib   \
                                  --build=$ICEPEARL_HOST  \
                                  --host=$ICEPEARL_TARGET \
				  --enable-kernel=4.4     \
				  --with-headers=/usr/include > /dev/null

_msg "Building glibc"
make -j4 > /dev/null

_msg "Installing glibc"
make DESTDIR=$ICEPEARL_TOOLCHAIN install > /dev/null

_msg "Fixing glibc's hard coded path"
sed '/RTLDLIST=/s@/usr@@g' -i $ICEPEARL_TOOLCHAIN/usr/bin/ldd

# 5. gcc (libstdc++-v3)
mkdir $ICEPEARL_BUILD/libstdc++-v3 && cd $ICEPEARL_BUILD/libstdc++-v3
$ICEPEARL_SOURCES/gcc/libstdc++-v3/configure --prefix=/usr           \
	                                     --libdir=/usr/lib       \
					     --libexecdir=/usr/lib   \
					     --build=$ICEPEARL_HOST  \
					     --host=$ICEPEARL_TARGET \
					     --disable-multilib      \
					     --disable-nls           \
					     --with-gxx-include-dir=$ICEPEARL_TOOLCHAIN/$ICEPEARL_TARGET/include/c++/* > /dev/null

_msg "Building gcc (libstdc++-v3)"
make -j4 > /dev/null

_msg "Installing gcc (libstdc++-v3)"
make install > /dev/null

# 6. gcc (libgomp)

_msg "Building gcc (libgomp)"
make -j4 all-target-libgomp > /dev/null

_msg "Installing gcc (libgomp)"
make install-target-libgomp > /dev/null

# 8. gcc derivatives
cd $ICEPEARL_SOURCES/gcc
_msg "Creating limits.h"
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($ICEPEARL_TARGET-gcc -print-libgcc-file-name)`/include/limits.h
_msg "Linking into $ICEPEARL_TARGET-cc"
ln -s $ICEPEARL_TARGET-gcc $ICEPEARL_TOOLCHAIN/bin/$ICEPEARL_TARGET-cc
