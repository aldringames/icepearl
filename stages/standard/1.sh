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
  ln -sf bin usr/sbin 
  ln -sf lib usr/lib64

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
wget -q -O- https://ftp.gnu.org/pub.gnu/binutils/binutils-2.40.tar.xz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/binutils
cd $ICEPEARL_SOURCES/binutils
sed '6009s/$add_dir//' -i ltmain.sh

_msg "Configuring binutils"
mkdir $ICEPEARL_BUILD/binutils && cd $ICEPEARL_BUILD/binutils
AR=$BLD_AR             \
AS=$BLD_AS             \
CC=$BLD_CC             \
CXX=$BLD_CXX           \
CFLAGS=$BLD_CFLAGS     \
CXXFLAGS=$BLD_CXXFLAGS \
LDFLAGS=$BLD_LDFLAGS   \
$ICEPEARL_SOURCES/binutils/configure "${_configure_options[@]:?_configure_options unset}" \
	                             --enable-shared                                      \
				     --enable-64-bit-bfd                                  \
	                             --disable-nls                                        \
				     --disable-werror > /dev/null

_msg "Building binutils"
make -j4 > /dev/null

_msg "Installing binutils"
make DESTDIR=$ICEPEARL_ROOTFS prefix=/usr tooldir=/usr install > /dev/null

# 3. gcc

# 4. glibc
_msg "Downloading and extracting glibc"
mkdir $ICEPEARL_SOURCES/glibc
wget -q -O- https://ftp.gnu.org/pub/gnu/glibc/glibc-2.37.tar.xz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/glibc
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

ls $ICEPEARL_ROOTFS
ls $ICEPEARL_ROOTFS/*
