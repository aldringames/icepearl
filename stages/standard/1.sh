#!/bin/bash -e
CURDIR="$(pwd)"
source ${CURDIR}/commons/functions.sh
source ${CURDIR}/commons/vars.sh

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
  ln -sfv usr/bin sbin
  ln -sfv usr/bin bin
  ln -sfv usr/lib lib
  ln -sfv usr/lib lib64
  ln -sfv bin usr/sbin 
  ln -sfv lib usr/lib64

  ln -sfv run var/run
  ln -sfv run/lock var/lock

  install -dv -m 0750 root
  install -dv -m 1777 tmp var/tmp
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
		    --infodit=/usr/share/info
		    --mandir=/usr/share/man
	            --build=$ICEPEARL_HOST
	            --host=$ICEPEARL_HOST)

# 1. glibc
_msg "Downloading and extracting glibc"
mkdir $ICEPEARL_SOURCES/glibc
wget -q -O- https://ftp.gnu.org/gnu/glibc/glibc-2.37.tar.xz | tar -xJf- --strip-components=1 -C $ICEPEARL_SOURCES/glibc
cd $ICEPEARL_SOURCES/glibc
sed '/width -=/s/workend - string/number_length/' -i stdio-common/vfprintf-process-arg.c

_msg "Configuring glibc"
mkdir $ICEPEARL_BUILD/glibc && cd $ICEPEARL_BUILD/glibc
cat > configparms <<EOF
slibdir=/usr/lib
rtlddir=/usr/lib
sbindir=/usr/bin
rootsbindir=/usr/bib
EOF
$ICEPEARL_SOURCES/glibc/configure "${_configure_options[@]:?_configure_options unset}" \
	                          --with-headers=/usr/include                          \
	                          --enable-kernel=4.4                                  \
				  --enable-stack-protector=strong                      \
				  --disable-werror > /dev/null

_msg "Building glibc"
make -j4 > /dev/null

_msg "Installing glibc"
make DESTDIR=$ICEPEARL_ROOTFS install

ls $ICEPEARL_ROOTFS
