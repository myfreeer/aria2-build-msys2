#!bash
case $MSYSTEM in
MINGW32)
    export MINGW_PACKAGE_PREFIX=mingw-w64-i686
    export HOST=i686-w64-mingw32
    ;;
MINGW64)
    export MINGW_PACKAGE_PREFIX=mingw-w64-x86_64
    export HOST=x86_64-w64-mingw32
    ;;
esac

# workaround git user name and email not set
GIT_USER_NAME="$(git config --global user.name)"
GIT_USER_EMAIL="$(git config --global user.email)"
if [[ "${GIT_USER_NAME}" = "" ]]; then
    git config --global user.name "Name"
fi
if [[ "${GIT_USER_EMAIL}" = "" ]]; then
    git config --global user.email "you@example.com"
fi

pacman -S --noconfirm --needed $MINGW_PACKAGE_PREFIX-gcc \
    $MINGW_PACKAGE_PREFIX-winpthreads

PREFIX=/usr/local/$HOST
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

# expat
expat_ver="$(clean_html_index https://sourceforge.net/projects/expat/files/expat/ 'expat/[0-9]+\.[0-9]+\.[0-9]+')"
expat_ver="$(get_last_version "${expat_ver}" expat '2\.\d+\.\d+')"
expat_ver="${expat_ver:-2.2.10}"
wget -c --no-check-certificate "https://downloads.sourceforge.net/project/expat/expat/${expat_ver}/expat-${expat_ver}.tar.bz2"
tar xf "expat-${expat_ver}.tar.bz2"
cd "expat-${expat_ver}" || exit 1
./configure \
    --disable-shared \
    --enable-static \
    --prefix=/usr/local/$HOST \
    --host=$HOST
make install -j$CPUCOUNT
cd ..
rm -rf "expat-${expat_ver}"

# sqlite
sqlite_ver=$(clean_html_index_sqlite "https://www.sqlite.org/download.html")
[[ ! "$sqlite_ver" ]] && sqlite_ver="2020/sqlite-autoconf-3340000.tar.gz"
sqlite_file=$(echo ${sqlite_ver} | grep -ioP "(sqlite-autoconf-\d+\.tar\.gz)")
wget -c --no-check-certificate "https://www.sqlite.org/${sqlite_ver}"
tar xf "${sqlite_file}"
echo ${sqlite_ver}
sqlite_name=$(echo ${sqlite_ver} | grep -ioP "(sqlite-autoconf-\d+)")
cd "${sqlite_name}" || exit 1
./configure \
    --disable-shared \
    --enable-static \
    --prefix=/usr/local/$HOST \
    --host=$HOST
make install -j$CPUCOUNT
cd ..
rm -rf "${sqlite_name}"

# c-ares: Async DNS support
[[ ! "$cares_ver" ]] &&
    cares_ver="$(clean_html_index https://c-ares.haxx.se/)" &&
    cares_ver="$(get_last_version "$cares_ver" c-ares "1\.\d+\.\d")"
cares_ver="${cares_ver:-1.17.1}"
echo "c-ares-${cares_ver}"
wget -c --no-check-certificate "https://c-ares.haxx.se/download/c-ares-${cares_ver}.tar.gz"
tar xf "c-ares-${cares_ver}.tar.gz"
cd "c-ares-${cares_ver}" || exit 1
# https://github.com/c-ares/c-ares/issues/384
# https://github.com/c-ares/c-ares/commit/c35f8ff50710cd38776e9560389504dbd96307fa
if [ "${cares_ver}" = "1.17.1" ]; then
    patch -p1 < ../c-ares-1.17.1-fix-autotools-static-library.patch
    autoreconf -fi || autoreconf -fiv
fi
./configure \
    --disable-shared \
    --enable-static \
    --without-random \
    --disable-tests \
    --prefix=/usr/local/$HOST \
    --host=$HOST
make install -j$CPUCOUNT
cd ..
rm -rf "c-ares-${cares_ver}"

# libssh2
[[ ! "$ssh_ver" ]] &&
    ssh_ver="$(clean_html_index https://libssh2.org/download/)" &&
    ssh_ver="$(get_last_version "$ssh_ver" tar.gz "1\.\d+\.\d")"
ssh_ver="${ssh_ver:-1.9.0}"
echo "${ssh_ver}"
wget -c --no-check-certificate "https://libssh2.org/download/libssh2-${ssh_ver}.tar.gz"
tar xf "libssh2-${ssh_ver}.tar.gz"
cd "libssh2-${ssh_ver}"
# https://github.com/libssh2/libssh2/pull/479
# https://github.com/libssh2/libssh2/commit/ba149e804ef653cc05ed9803dfc94519ce9328f7
if [ "${ssh_ver}" = "1.9.0" ]; then
    patch -p1 < ../libssh2-1.9.0-wincng-multiple-definition.patch
fi
./configure \
    --disable-shared \
    --enable-static \
    --prefix=/usr/local/$HOST \
    --host=$HOST \
    --with-crypto=wincng \
    LIBS="-lws2_32"
make install -j$CPUCOUNT
cd ..
rm -rf "libssh2-${ssh_ver}"

if [[ -d aria2 ]]; then
    cd aria2
    git checkout master || git checkout HEAD
    git reset --hard origin || git reset --hard
    git pull
else
    git clone https://github.com/aria2/aria2 --depth=1 --config http.sslVerify=false
    cd aria2 || exit 1
fi
git checkout -b patch
git am -3 ../aria2-*.patch

autoreconf -fi || autoreconf -fiv
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
    LDFLAGS="-L$PREFIX/lib -Wl,--gc-sections,--build-id=none" \
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
make -j$CPUCOUNT
strip -s src/aria2c.exe
git checkout master
git branch patch -D
cd ..
