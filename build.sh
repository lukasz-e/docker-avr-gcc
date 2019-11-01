#!/usr/bin/env bash

SRC="src"
BUILD="build"
INSTALL="/opt/avr" # tar.bz2 needs a prefix of 'avr-gcc'
DOWNLOAD="download"
mkdir ${SRC}
mkdir ${BUILD}
mkdir ${INSTALL}
mkdir ${DOWNLOAD}
root=$(pwd)
cores=4
VERSION_BINUTILS="2.32"
VERSION_GCC="9.2.0"
VERSION_LIBC="2.0.0"
GCC_PROGRAM_SUFFIX="9"

# Get sources
cd ${DOWNLOAD}
[ -f avr-binutils-${VERSION_BINUTILS}-size.patch ] || wget   "https://dl.bintray.com/osx-cross/avr-patches/avr-binutils-${VERSION_BINUTILS}-size.patch" 
[ -f avr-libc-${VERSION_LIBC}-atmega168pb.patch ] || wget   "https://dl.bintray.com/osx-cross/avr-patches/avr-libc-${VERSION_LIBC}-atmega168pb.patch" 
[ -f binutils-${VERSION_BINUTILS}.tar.bz2 ] || wget  "https://ftp.gnu.org/gnu/binutils/binutils-${VERSION_BINUTILS}.tar.bz2" 
[ -f gcc-${VERSION_GCC}.tar.xz ] || wget "https://ftp.gnu.org/gnu/gcc/gcc-${VERSION_GCC}/gcc-${VERSION_GCC}.tar.xz" 
[ -f avr-libc-${VERSION_LIBC}.tar.bz2 ] || wget "https://download.savannah.gnu.org/releases/avr-libc/avr-libc-${VERSION_LIBC}.tar.bz2" 

cd ${root}/${SRC}
tar xf "${root}/${DOWNLOAD}/binutils-${VERSION_BINUTILS}.tar.bz2"
tar xf "${root}/${DOWNLOAD}/gcc-${VERSION_GCC}.tar.xz"
tar xf "${root}/${DOWNLOAD}/avr-libc-${VERSION_LIBC}.tar.bz2"

# Build binutils first
cd ${root}
cd ${SRC}/binutils-${VERSION_BINUTILS}
# patch size file
patch -g 0 -f -p0 -i ${root}/${DOWNLOAD}/avr-binutils-${VERSION_BINUTILS}-size.patch
mkdir build && cd build
# configure and make
../configure --prefix=${INSTALL}/avr-binutils/ --target=avr --disable-nls --disable-werror
make -j${cores}
make install

# prepend path of newly compiled avr-gcc
export PATH=${INSTALL}/avr-binutils/bin:$PATH

cd ${root}
cd ${SRC}/gcc-${VERSION_GCC}
mkdir build && cd build
../configure --target=avr --prefix=${INSTALL}/avr-gcc/ \
        --with-ld=${INSTALL}/avr-binutils/bin/avr-ld \
        --with-as=${INSTALL}/avr-binutils/bin/avr-as \
        --program-suffix=${GCC_PROGRAM_SUFFIX} \
        --program-prefix="avr-" \
        --enable-languages=c,c++ --with-dwarf2 \
        --disable-nls --disable-libssp --disable-shared \
        --disable-threads --disable-libgomp --disable-bootstrap
make -j${cores}
make install

# prepend path of newly compiled avr-gcc
export PATH=${INSTALL}/avr-gcc/bin:$PATH
export CC=avr-gcc9

cd ${root}
cd ${SRC}/avr-libc-${VERSION_LIBC}
patch -g 0 -f -p1 -i ${root}/${DOWNLOAD}/avr-libc-${VERSION_LIBC}-atmega168pb.patch
build=`./config.guess`
./configure --build=${build} --prefix=${INSTALL}/avr-gcc --host=avr
make install -j${cores}

cd ${root}
tar cvf avrgcc_dist.tar.bz2 /opt/avr
rm -r build src
#rm avr-binutils-${VERSION_BINUTILS}-size.patch
#rm avr-libc-${VERSION_LIBC}-atmega168pb.patch

