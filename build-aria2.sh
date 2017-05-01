#! /bin/bash

test -z "$HOST" && HOST=x86_64-w64-mingw32
test -z "$PREFIX" && PREFIX=/usr/local/$HOST
CPUCOUNT=$(grep -c ^processor /proc/cpuinfo)

wget --no-check-certificate https://downloads.sourceforge.net/project/expat/expat/2.2.0/expat-2.2.0.tar.bz2
tar xf expat-2.2.0.tar.bz2
cd expat-2.2.0
./configure \
    --disable-shared \
    --enable-static \
    --prefix=/usr/local/$HOST \
    --host=$HOST
make install -j$CPUCOUNT
cd ..

wget --no-check-certificate https://www.sqlite.org/2017/sqlite-autoconf-3160200.tar.gz
tar xf sqlite-autoconf-3160200.tar.gz
cd sqlite-autoconf-3160200
./configure \
    --disable-shared \
    --enable-static \
    --prefix=/usr/local/$HOST \
    --host=$HOST \
make install -j$CPUCOUNT
cd ..

wget --no-check-certificate https://c-ares.haxx.se/download/c-ares-1.12.0.tar.gz
tar xf c-ares-1.12.0.tar.gz
cd c-ares-1.12.0 && \
./configure \
    --disable-shared \
    --enable-static \
    --without-random \
    --prefix=/usr/local/$HOST \
    --host=$HOST \
    LIBS="-lws2_32"
make install -j$CPUCOUNT
cd ..

wget --no-check-certificate https://libssh2.org/download/libssh2-1.8.0.tar.gz
tar xf libssh2-1.8.0.tar.gz
cd libssh2-1.8.0
./configure \
    --disable-shared \
    --enable-static \
    --prefix=/usr/local/$HOST \
    --host=$HOST \
    --without-openssl \
    --with-wincng \
    LIBS="-lws2_32"
make install -j$CPUCOUNT
cd ..

git clone https://github.com/aria2/aria2 --depth=1
cd aria2
patch -Np1 <../aria2.diff
./configure \
    --host=$HOST \
    --prefix=$PREFIX \
    --without-included-gettext \
    --disable-nls \
    --with-libcares \
    --without-gnutls \
    --without-openssl \
    --with-sqlite3 \
    --without-libxml2 \
    --with-libexpat \
    --with-libz \
    --with-libgmp \
    --with-libssh2 \
    --without-libgcrypt \
    --without-libnettle \
    --with-cppunit-prefix=$PREFIX \
    ARIA2_STATIC=yes \
    CPPFLAGS="-I$PREFIX/include" \
    LDFLAGS="-L$PREFIX/lib" \
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
make -j$CPUCOUNT
strip src/aria2c.exe