#!/bin/bash -e
CURDIR="$(pwd)"
source ${CURDIR}/common/functions.sh
source ${CURDIR}/common/vars.sh

_msg "Dwleting icepearl directory"
rm -rf $ICEPEARL_DIR
_msg "Preparing icepearl directores"
mkdir -p $ICEPEARL_DIR/{sources,rootfs,iso,initrd}
_msg "Preparing icepearl rootfs directories"
pushd $ICEPEARL_ROOTFS
  mkdir -p {boot,home,mnt,opt,srv}                             \
           {etc,var}                                           \
           etc/{opt,sysconfig}                                 \
           usr/{bin,lib}                                       \
           usr/lib/firmware                                    \
           usr/{,local/}{include,src}                          \
           usr/local/{sbin,bin,lib}                            \
           usr/{,local/}share/{color,dict,doc,info,locale,man} \
           usr/{,local/}share/{misc,terminfo,zoneinfo}         \
           usr/{,local/}share/man/man{1..8}                    \
           var/{cache,local,log,mail,opt,spool}                \
           var/lib/{color,misc,locate}                         \
           {dev,proc,sys,run}
  # Using /usr merge
  ln -sf usr/bin sbin
  ln -sf usr/bin bin
  ln -sf usr/lib lib
  ln -sf usr/lib lib64
  ln -sf usr/lib libexec
  ln -sf bin usr/sbin
  ln -sf lib usr/lib64
  ln -sf lib usr/libexec

  ln -sf run var/run
  ln -sf run/lock var/lock

  install -d -m 0750 root
  install -d -m 1777 tmp var/tmp
popd 

# Configure options
_configure_options=(--prefix=/usr
	            --exec-prefix=/usr
	            --libdir=/usr/lib
		    --libexecdir=/usr/lib
		    --bindir=/usr/bin
		    --sbindir=/usr/bin
		    --sysconfdir=/etc
		    --docdir=/usr/share/doc
		    --infodir=/usr/share/info
		    --mandir=/usr/share/man
	            --build=$ICEPEARL_HOST
	            --host=$ICEPEARL_HOST)
# 1. binutils
_msg "Downloading and extracting binutils"
mkdir $ICEPEARL_SOURCES/binutils
wget -q -O- http://ftp.gnu.org/pub/gnu/binutils/binutils-2.40.tar.xz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/binutils
cd $ICEPEARL_SOURCES/binutils
sed '6009s/$add_dir//' -i ltmain.sh

_msg "Configuring binutils"
mkdir $ICEPEARL_BUILD/binutils && cd $ICEPEARL_BUILD/binutils
$ICEPEARL_SOURCES/binutils/configure "${_configure_options[@]:?_configure_options unset}" \
	                             --enable-shared                                      \
				     --enable-64-bit-bfd                                  \
	                             --disable-nls                                        \
				     --disable-werror > /dev/null

_msg "Building binutils"
make -j4 > /dev/null

_msg "Installing binutils"
make DESTDIR=$ICEPEARL_ROOTFS prefix=/usr tooldir=/usr install > /dev/null

# 2. gcc
_msg "Downloading and extracting gcc"
mkdir $ICEPEARL_SOURCES/gcc
wget -q -O- http://ftp.gnu.org/pub/gnu/gcc/gcc-13.1.0/gcc-13.1.0.tar.xz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/gcc
cd $ICEPEARL_SOURCES/gcc
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
sed '/thread_header =/s/@.*@/gthr-posix.h/' -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

_msg "Configuring gcc"
mkdir $ICEPEARL_BUILD/gcc && cd $ICEPEARL_BUILD/gcc
$ICEPEARL_SOURCES/gcc/configure "${_configure_options[@]:?_configure_options unset}" \
	                        --target=$ICEPEARL_HOST                              \
				--with-build-syroot=/                                \
				--enable-default-pie                                 \
				--enable-default-ssp                                 \
				--disable-multilib                                   \
				--disable-nls                                        \
				--disable-libatomic                                  \
				--disable-libgomp                                    \
				--disable-libquadmath                                \
				--disable-libssp                                     \
				--disable-libvtv                                     \
				--enable-languages=c,c++                             \
				LDFLAGS_FOR_TARGET=-L$PWD/$ICEPEARL_HOST/libgcc > /dev/null

_msg "Building gcc"
make -j4 > /dev/null

_msg "Installing gcc"
make DESTDIR=$ICEPEARL_ROOTFS install > /dev/null

_msg "Linking gcc as cc"
ln -s gcc $ICEPEARL_ROOTFS/usr/bin/cc

# 3. glibc
_msg "Downloading and extracting glibc"
mkdir $ICEPEARL_SOURCES/glibc
wget -q -O- http://ftp.gnu.org/pub/gnu/glibc/glibc-2.37.tar.xz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/glibc
cd $ICEPEARL_SOURCES/glibc
sed '/width -=/s/workend - string/number_length/' -i stdio-common/vfprintf-process-arg.c

_msg "Configuring glibc"
mkdir $ICEPEARL_BUILD/glibc && cd $ICEPEARL_BUILD/glibc
cat > configparms <<EOF
slibdir=/usr/lib
rtlddir=/usr/lib
sbindir=/usr/bin
rootsbindir=/usr/bin
EOF
$ICEPEARL_SOURCES/glibc/configure "${_configure_options[@]:?_configure_options unset}" \
	                          --with-headers=/usr/include                          \
	                          --enable-kernel=4.4                                  \
				  --enable-stack-protector=strong                      \
				  --disable-werror > /dev/null

_msg "Building glibc"
make -j4 > /dev/null

_msg "Installing glibc"
make DESTDIR=$ICEPEARL_ROOTFS install > /dev/null

# 4. linux-headers
_msg "Downloading and extracting linux-headers"
mkdir $ICEPEARL_SOURCES/linux-headers
wget -q -O- https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable-rc.git/snapshot/linux-stable-rc-4.14.316.tar.gz | tar -xzf- --strip-components=1 -C $ICEPEARL_SOURCES/linux-headers
cd $ICEPEARL_SOURCES/linux-headers

_msg "Building linux-headers"
make mrproper > /dev/null

_msg "Installing linux-headers"
make INSTALL_HDR_PATH="${ICEPEARL_ROOTFS}/usr" headers_install > /dev/null

# 5. m4
_msg "Downloading and extracting m4"
mkdir $ICEPEARL_SOURCES/m4
wget -q -O- http://ftp.gnu.org/pub/gnu/m4/m4-1.4.19.tar.xz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/m4
cd $ICEPEARL_SOURCES/m4

_msg "Configuring m4"
./configure "${_configure_options[@]:?_configure_options unset}" > /dev/null

_msg "Building m4"
make -j4 > /dev/null

_msg "Installing m4"
make DESTDIR=$ICEPEARL_ROOTFS install > /dev/null

# 6. make
_msg "Downloading and extracting make"
mkdir $ICEPEARL_SOURCES/make
wget -q -O- http://ftp.gnu.org/pub/gnu/make/make-4.4.1.tar.gz | tar -xzf- --strip-components=1 -C $ICEPEARL_SOURCES/make
cd $ICEPEARL_SOURCES/make

_msg "Configuring make"
./configure "${_configure_options[@]:?_configure_options unset}" > /dev/null

_msg "Building make"
make -j4 > /dev/null

_msg "Installing make"
make DESTDIR=$ICEPEARL_ROOTFS install > /dev/null

# 7. file
mkdir $ICEPEARL_SOURCES/file
wget -q -O- https://astron.com/pub/file/file-5.44.tar.gz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/file
cd $ICEPEARL_SOURCES/file

_msg "Configuring file"
./configure "${_configure_options[@]:?_configure_options unset}" \
	    --disable-libseccomp > /dev/null

_msg "Building file"
make -j4 > /dev/null

_msg "Installing file"
make DESTDIR=$ICEPEARL_ROOTFS install > /dev/null

ls $ICEPEARL_ROOTFS/*
