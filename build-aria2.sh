#!bash

test -z "$HOST" && HOST=x86_64-w64-mingw32
test -z "$PREFIX" && PREFIX=/usr/local/$HOST
CPUCOUNT=$(grep -c ^processor /proc/cpuinfo)
curl_opts=(/usr/bin/curl --connect-timeout 15 --retry 3
    --retry-delay 5 --silent --location --insecure --fail)

clean_html_index() {
    local url="$1"
    local filter="${2:-(?<=href=\")[^\"]+\.(tar\.(gz|bz2|xz)|7z)}"
    "${curl_opts[@]}" -l "$url" | grep -ioP "$filter" | sort -uV
}

clean_html_index_sqlite() {
    local url="$1"
    local filter="${2:-(\d+\/sqlite-autoconf-\d+\.tar\.gz)}"
    "${curl_opts[@]}" -l "$url" | grep -ioP "$filter" | sort -uV | tail -1
}

get_last_version() {
    local filelist="$1"
    local filter="$2"
    local version="$3"
    local ret
    ret="$(echo "$filelist" | /usr/bin/grep -E "$filter" | sort -V | tail -1)"
    [[ -n "$version" ]] && ret="$(echo "$ret" | /usr/bin/grep -oP "$version")"
    echo "$ret"
}

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

sqlite_ver=$(clean_html_index_sqlite "https://www.sqlite.org/download.html")
[[ ! "$sqlite_ver" ]] && sqlite_ver="2017/sqlite-autoconf-3180000.tar.gz"
sqlite_file=$(echo ${sqlite_ver} | grep -ioP "(sqlite-autoconf-\d+\.tar\.gz)")
wget --no-check-certificate "https://www.sqlite.org/${sqlite_ver}"
tar xf "${sqlite_file}"
sqlite_name=$(echo ${sqlite_ver} | grep -ioP "(sqlite-autoconf-\d+)")
cd "${sqlite_name}"
./configure \
    --disable-shared \
    --enable-static \
    --prefix=/usr/local/$HOST \
    --host=$HOST
make install -j$CPUCOUNT
cd ..

[[ ! "$cares_ver" ]] &&
    cares_ver="$(clean_html_index https://c-ares.haxx.se/download/)" &&
    cares_ver="$(get_last_version "$cares_ver" c-ares "1\.\d+\.\d")"
cares_ver="${cares_ver:-1.12.0}"
wget --no-check-certificate "https://c-ares.haxx.se/download/c-ares-${cares_ver}.tar.gz"
tar xf "c-ares-${cares_ver}.tar.gz"
cd "c-ares-${cares_ver}" && \
./configure \
    --disable-shared \
    --enable-static \
    --without-random \
    --prefix=/usr/local/$HOST \
    --host=$HOST \
    LIBS="-lws2_32"
make install -j$CPUCOUNT
cd ..

[[ ! "$ssh_ver" ]] &&
    ssh_ver="$(clean_html_index https://libssh2.org/download/)" &&
    ssh_ver="$(get_last_version "$ssh_ver" tar.gz "1\.\d+\.\d")"
ssh_ver="${ssh_ver:-1.8.0}"
wget --no-check-certificate "https://libssh2.org/download/libssh2-${ssh_ver}.tar.gz"
tar xf "libssh2-${ssh_ver}.tar.gz"
cd "libssh2-${ssh_ver}"
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
autoreconf -i
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