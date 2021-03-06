### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2a"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.openssl.org/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 < "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" \
  --openssldir="${DEST}/etc/ssl" \
  --with-zlib-include="${DEPS}/include" \
  --with-zlib-lib="${DEPS}/lib" \
  shared zlib-dynamic threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS}
sed -i -e "s/-O3//g" Makefile
make -j1
make install_sw
mkdir -p "${DEST}/libexec"
cp -avR "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -avR "${DEPS}/lib"/libssl* "${DEST}/lib/"
cp -avR "${DEPS}/lib"/libcrypto* "${DEST}/lib/"
cp -avR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -avR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -fv "${DEST}/lib"/*.a
sed -i -e "s|^exec_prefix=.*|exec_prefix=${DEST}|g" "${DEST}/lib/pkgconfig/openssl.pc"
popd
}

### SQLITE ###
_build_sqlite() {
local VERSION="3080900"
local FOLDER="sqlite-autoconf-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sqlite.org/2015/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### ICU ###
_build_icu() {
local VERSION="55.1"
local FOLDER="icu"
local FILE="icu4c-${VERSION/./_}-src.tgz"
local URL="http://download.icu-project.org/files/icu4c/${VERSION}/${FILE}"
local ICU_HOST="${PWD}/target/icu"
local ICU_NATIVE="${PWD}/target/icu-build-native"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
rm -vfr "${ICU_NATIVE}"
mkdir -p "${ICU_NATIVE}"
( . uncrosscompile.sh
  pushd "${ICU_NATIVE}"
  "${ICU_HOST}/source/configure"
  make )
pushd "target/${FOLDER}"
./source/configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --disable-extras --disable-samples --disable-tests --with-cross-build="${ICU_NATIVE}"
make
make install
popd
}

### LIBXML2 ###
_build_libxml2() {
local VERSION="2.9.2"
local FOLDER="libxml2-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://xmlsoft.org/libxml2/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PATH=$DEPS/bin:$PATH ./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --with-zlib --with-icu --without-python LIBS="-lz"
make
make install
popd
}

### EXPAT ###
_build_expat() {
local VERSION="2.1.0"
local FOLDER="expat-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/expat/files/expat/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### PCRE ###
_build_pcre() {
local VERSION="8.36"
local FOLDER="pcre-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/pcre/files/pcre/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --enable-unicode-properties
make
make install
popd
}

### NCURSES ###
_build_ncurses() {
local VERSION="5.9"
local FOLDER="ncurses-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/gnu/ncurses/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --datadir="${DEST}/share" --with-shared --enable-rpath
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### READLINE ###
_build_readline() {
local VERSION="6.3"
local FOLDER="readline-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://ftp.cwru.edu/pub/bash/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --with-curses bash_cv_wcwidth_broken=no
make
make -j1 install
popd
}

### LUA ###
_build_lua() {
# Apache 2.4.12 does not support Lua 5.3.x
local VERSION="5.2.4"
local FOLDER="lua-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.lua.org/ftp/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-liblua.so.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 < "${FOLDER}-liblua.so.patch"
make PLAT=linux RANLIB="${RANLIB}" CC="${CC}" AR="${AR} rcu" MYCFLAGS="${CFLAGS:-}" MYLDFLAGS="${LDFLAGS:-}" MYLIBS="-lncurses"
make install INSTALL_TOP="${DEPS}" INSTALL_LIB="${DEST}/lib"
rm -vf "${DEST}/lib/liblua.a"
ln -fs "liblua.so" "${DEST}/lib/liblua.so.1"
popd
}

### APR ###
_build_apr() {
local VERSION="1.5.1"
local FOLDER="apr-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/mirror/apache/dist/apr/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --enable-nonportable-atomics ac_cv_file__dev_zero=yes ac_cv_func_setpgrp_void=yes apr_cv_process_shared_works=yes apr_cv_mutex_robust_shared=no apr_cv_tcp_nodelay_with_cork=yes ac_cv_sizeof_struct_iovec=8 apr_cv_mutex_recursive=yes ac_cv_sizeof_pid_t=4 ac_cv_sizeof_size_t=4 ac_cv_struct_rlimit=yes ap_cv_atomic_builtins=yes apr_cv_epoll=yes apr_cv_epoll_create1=yes
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"
make
make install
popd
}

### APR-UTIL ###
_build_aprutil() {
local VERSION="1.5.4"
local FOLDER="apr-util-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/mirror/apache/dist/apr/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --with-apr="${DEPS}" --without-apr-iconv --with-crypto --with-openssl="${DEPS}" --with-sqlite3="${DEPS}" --with-expat="${DEPS}"
make
make install
popd
}

### HTTPD ###
_build_httpd() {
local VERSION="2.4.12"
local FOLDER="httpd-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/mirror/apache/dist/httpd/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"

cat >> config.layout << EOF
# Layout for Drobo devices
<Layout Drobo>
    prefix:        ${DEST}
    exec_prefix:   \${prefix}
    bindir:        \${prefix}/bin
    sbindir:       \${prefix}/sbin
    libdir:        \${prefix}/lib
    libexecdir:    \${prefix}/modules
    mandir:        \${prefix}/man
    sysconfdir:    \${prefix}/etc
    includedir:    \${prefix}/include
    installbuilddir: \${includedir}/build
    localstatedir: \${prefix}
    datadir:       \${localstatedir}/www
    errordir:      \${datadir}/error
    iconsdir:      \${datadir}/icons
    htdocsdir:     \${datadir}/html
    manualdir:     \${datadir}/manual
    cgidir:        \${datadir}/cgi-bin
    runtimedir:    /tmp/DroboApps/apache2
    logfiledir:    \${prefix}/logs
    proxycachedir: \${datadir}/cache/root
</Layout>
EOF

./configure --host="${HOST}" --prefix="${DEST}" --disable-static --enable-mods-shared=all --enable-load-all-modules --enable-so --enable-layout=Drobo --with-mpm=prefork --with-apr="${DEPS}" --with-apr-util="${DEPS}" --with-pcre="${DEPS}/bin/pcre-config" --with-z="${DEPS}" --with-ssl="${DEPS}" --with-lua="${DEPS}" --with-libxml2="${DEPS}/include/libxml2" --disable-ext-filter ap_cv_void_ptr_lt_long=no
sed -i -e "/gen_test_char_OBJECTS = gen_test_char.lo/d" -e "s/gen_test_char: \$(gen_test_char_OBJECTS)/gen_test_char: gen_test_char.c/" -e "s/\$(LINK) \$(EXTRA_LDFLAGS) \$(gen_test_char_OBJECTS) \$(EXTRA_LIBS)/\$(CC_FOR_BUILD) \$(CFLAGS_FOR_BUILD) -DCROSS_COMPILE -o \$@ \$</" server/Makefile
make CC_FOR_BUILD=/usr/bin/cc
make install
ln -fs "etc" "${DEST}/conf"
ln -fs "sbin/apachectl" "${DEST}/apachectl"
ln -fs "sbin/httpd" "${DEST}/httpd"
popd
}

### BZIP ###
_build_bzip() {
local VERSION="1.0.6"
local FOLDER="bzip2-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://bzip.org/1.0.6/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
sed -i -e "s/all: libbz2.a bzip2 bzip2recover test/all: libbz2.a bzip2 bzip2recover/" Makefile
make -f Makefile-libbz2_so CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" CFLAGS="${CFLAGS} -fpic -fPIC -Wall -D_FILE_OFFSET_BITS=64"
ln -s libbz2.so.1.0.6 libbz2.so
cp -avR *.h "${DEPS}/include/"
cp -avR *.so* "${DEST}/lib/"
popd
}

### LIBJPEG ###
_build_libjpeg() {
local VERSION="9a"
local FOLDER="jpeg-${VERSION}"
local FILE="jpegsrc.v${VERSION}.tar.gz"
local URL="http://www.ijg.org/files/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --enable-maxmem=8
make
make install
popd
}

### LIBPNG ###
_build_libpng() {
local VERSION="1.6.17"
local FOLDER="libpng-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/libpng/files/libpng16/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### FREETYPE ###
_build_freetype() {
local VERSION="2.5.5"
local FOLDER="freetype-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/freetype/files/freetype2/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --with-zlib="${DEPS}" --with-bzip2="${DEPS}"
make
make install
popd
}

### CURL ###
_build_curl() {
local VERSION="7.41.0"
local FOLDER="curl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://curl.haxx.se/download/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --disable-debug --disable-curldebug --with-zlib="${DEPS}" --with-ssl="${DEPS}" --with-random --with-ca-bundle="${DEST}/etc/ssl/certs/ca-certificates.crt" --enable-ipv6
make
make install
popd
}

### LIBMCRYPT ###
_build_libmcrypt() {
local VERSION="2.5.8"
local FOLDER="libmcrypt-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/mcrypt/files/Libmcrypt/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
make
make install
popd
}

### GMP ###
_build_gmp() {
local VERSION="6.0.0"
local FOLDER="gmp-${VERSION}"
local FILE="${FOLDER}a.tar.xz"
local URL="ftp://ftp.gnu.org/gnu/gmp/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### LIBXSLT ###
_build_libxslt() {
local VERSION="1.1.28"
local FOLDER="libxslt-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://xmlsoft.org/libxslt/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --with-libxml-prefix="${DEPS}" --without-debug --without-python --without-crypto
sed -i -e "/^.doc \\\\/d" Makefile
make
make install
popd
}

### BDB ###
_build_bdb() {
local VERSION="5.3.28"
local FOLDER="db-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://download.oracle.com/berkeley-db/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}/build_unix"
../dist/configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --enable-compat185 --enable-dbm
make
make install
popd
}

### MYSQL-CONNECTOR ###
_build_mysql() {
local VERSION="6.1.6"
local FOLDER="mysql-connector-c-${VERSION}-src"
local FILE="${FOLDER}.tar.gz"
local URL="http://cdn.mysql.com/Downloads/Connector-C/${FILE}"
export FOLDER_NATIVE="${PWD}/target/${FOLDER}-native"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
[   -d "${FOLDER_NATIVE}" ] && rm -fr "${FOLDER_NATIVE}"
[ ! -d "${FOLDER_NATIVE}" ] && cp -faR "target/${FOLDER}" "${FOLDER_NATIVE}"

# native compilation of comp_err
( source uncrosscompile.sh
  pushd "${FOLDER_NATIVE}"
  cmake .
  make comp_err )

pushd "target/${FOLDER}"
cat > "cmake_toolchain_file.${ARCH}" << EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR ${ARCH})
SET(CMAKE_C_COMPILER ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})
SET(CMAKE_AR ${AR})
SET(CMAKE_RANLIB ${RANLIB})
SET(CMAKE_STRIP ${STRIP})
SET(CMAKE_CROSSCOMPILING TRUE)
SET(STACK_DIRECTION 1)
SET(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN}/${HOST}/libc)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF

# Use existing zlib
ln -vfs libz.so "${DEST}/lib/libzlib.so"
mv -v zlib/CMakeLists.txt{,.orig}
touch zlib/CMakeLists.txt

# Fix regex to find openssl 1.0.2 version
sed -i -e "s/\^#define/^#[\t ]*define/g" -e "s/\+0x/*0x/g" cmake/ssl.cmake

LDFLAGS="${LDFLAGS} -lz" cmake . -DCMAKE_TOOLCHAIN_FILE="./cmake_toolchain_file.${ARCH}" -DCMAKE_AR="${AR}" -DCMAKE_STRIP="${STRIP}" -DCMAKE_INSTALL_PREFIX="${DEPS}" -DENABLED_PROFILING=OFF -DENABLE_DEBUG_SYNC=OFF -DWITH_PIC=ON -DWITH_SSL="${DEPS}" -DOPENSSL_ROOT_DIR="${DEST}" -DOPENSSL_INCLUDE_DIR="${DEPS}/include" -DOPENSSL_LIBRARY="${DEST}/lib/libssl.so" -DCRYPTO_LIBRARY="${DEST}/lib/libcrypto.so" -DWITH_ZLIB=system -DZLIB_INCLUDE_DIR="${DEPS}/include" -DCMAKE_REQUIRED_LIBRARIES=z -DHAVE_LLVM_LIBCPP_EXITCODE=1 -DHAVE_GCC_ATOMIC_BUILTINS=1

if ! make -j1; then
  sed -i -e "s|\&\& comp_err|\&\& ./comp_err|g" extra/CMakeFiles/GenError.dir/build.make
  cp -vf "${FOLDER_NATIVE}/extra/comp_err" extra/
  make -j1
fi
make install
cp -vfaR "${DEPS}/lib"/libmysql*.so* "${DEST}/lib/"
cp -vfaR include/*.h "${DEPS}/include/"
popd
}

### PHP ###
_build_php() {
# sudo apt-get install php5-cli
local VERSION="5.6.8"
local FOLDER="php-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ch1.php.net/get/${FILE}/from/this/mirror"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-950-Fix-dl-cross-compiling-issue.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 < "${FOLDER}-950-Fix-dl-cross-compiling-issue.patch"
./buildconf --force

sed -i -e "/unset ac_cv_func_dlopen/d" -e "/unset ac_cv_lib_dl_dlopen/d" configure
sed -i -e "s|\@\$(top_builddir)/sapi/cli/php|\@\$(PHP_EXECUTABLE)|" pear/Makefile.frag
# Symlinks required to satisfy PHP's simplistic library detection algorithm.
ln -fs "${DEST}/lib/libpcre.so" "${DEPS}/lib/"
ln -fs "${DEST}/lib/libexpat.so" "${DEPS}/lib/"
ln -fs "${DEST}/lib/libdb.so" "${DEPS}/lib/"

./configure --host="${HOST}" --prefix="${DEST}" \
 --enable-all=shared \
 --enable-opcache \
 --enable-cli \
 --enable-cgi \
 --enable-fpm \
 --disable-static \
 --disable-embed \
 --with-apxs2="${DEST}/bin/apxs" \
 --with-bz2=shared,"${DEPS}" \
 --with-config-file-path="${DEST}/etc" \
 --with-curl=shared,"${DEPS}" \
 --with-db4="${DEPS}" \
 --with-freetype-dir="${DEPS}" \
 --with-gd=shared \
 --with-gmp=shared,"${DEPS}" \
 --with-iconv=shared \
 --with-icu-dir="${DEPS}" \
 --with-jpeg-dir="${DEPS}" \
 --with-libexpat-dir="${DEPS}" \
 --with-mcrypt=shared,"${DEPS}" \
 --with-mysql=shared,"${DEPS}" \
 --with-mysqli=shared,"${DEPS}/bin/mysql_config" \
 --with-openssl="${DEPS}" \
 --with-openssl-dir="${DEPS}" \
 --with-pcre-dir="${DEPS}" \
 --with-pcre-regex="${DEPS}" \
 --with-png-dir="${DEPS}" \
 --with-pdo-mysql=shared,"${DEPS}/bin/mysql_config" \
 --with-pdo-sqlite=shared,"${DEPS}" \
 --with-pear=shared \
 --with-readline="${DEPS}" \
 --with-sqlite3=shared,"${DEPS}" \
 --with-xmlrpc=shared \
 --with-xsl=shared,"${DEPS}" \
 --with-zlib=shared,"${DEPS}" \
 --with-zlib-dir="${DEPS}" \
 --without-{apxs,adabas,aolserver,birdstep,caudium,continuity,custom-odbc,db1,db2,db3,dbmaker,dbm,empress,empress-bcs,enchant,esoob,gdbm,ibm-db2,iconv,imap,interbase,iodbc,isapi,kerberos,ldap,libedit,litespeed,milter,mssql,ndbm,nsapi,oci8,ODBCRouter,pdo-dblib,pdo-firebird,pdo-oci,pdo-odbc,pdo-pgsql,pgsql,phttpd,pi3web,pspell,qdbm,recode,roxen,sapdb,snmp,solid,sybase-ct,t1lib,tcadb,thttpd,tidy,tux,unixODBC,vpx-dir,webjames,xpm-dir} \
 CPPFLAGS="-I$DEPS/include/freetype2 -I$DEPS/include/freetype2" LIBS="-lssl -lpthread" \
 ac_cv_func_dlopen=yes ac_cv_lib_dl_dlopen=yes ac_cv_php_xml2_config_path="${DEPS}/bin/xml2-config" ac_cv_func_gethostname=yes ac_cv_func_getaddrinfo=yes ac_cv_func_utime_null=yes ac_cv_func_memcmp_working=yes ac_cv_func_fnmatch_works=yes ac_cv_crypt_ext_des=yes ac_cv_crypt_md5=yes ac_cv_crypt_blowfish=yes ac_cv_crypt_SHA512=yes ac_cv_crypt_SHA256=yes \
 php_cv_sizeof_int8=0 php_cv_sizeof_uint8=0 php_cv_sizeof_int16=0 php_cv_sizeof_uint16=0 php_cv_sizeof_int32=0 php_cv_sizeof_uint32=0 php_cv_sizeof_uchar=0 php_cv_sizeof_ulong=4 php_cv_sizeof_int8_t=1 php_cv_sizeof_uint8_t=1 php_cv_sizeof_int16_t=2 php_cv_sizeof_uint16_t=2 php_cv_sizeof_int32_t=4 php_cv_sizeof_uint32_t=4 php_cv_sizeof_int64_t=8 php_cv_sizeof_uint64_t=8 php_cv_sizeof_intmax_t=8 php_cv_sizeof_ptrdiff_t=4 php_cv_sizeof_ssize_t=4

make PHP_PHARCMD_EXECUTABLE=/usr/bin/php
make -j1 PHP_PHARCMD_EXECUTABLE=/usr/bin/php PHP_EXECUTABLE=/usr/bin/php PHP_PEAR_SYSCONF_DIR="${DEST}/etc" install
popd
}

### DEFAULT FILES ###
_build_defaults() {
local PHP_INI="${DEST}/etc/php.ini.default"
cat > "${PHP_INI}" << EOF
short_open_tag = On
date.timezone = "America/Los_Angeles"
include_path = ".:${DEST}/lib/php"
error_log = "${DEST}/logs/php_log"
EOF
for e in "${DEST}/lib/php/extensions/"no-debug-non-zts-*/*.so; do
  if [ "$(basename "${e}")" = "opcache.so" ]; then
    echo "zend_extension=$(basename "${e}")" >> "${PHP_INI}"
  else
    echo "extension=$(basename "${e}")" >> "${PHP_INI}"
  fi
done

find "${DEST}" -type f -name "*.conf" -print | while read conffile; do
  mv -vf "${conffile}" "${conffile}.default"
done
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
}

### BUILD ###
_build() {
  _build_zlib
  _build_openssl
  _build_sqlite
  _build_icu
  _build_libxml2
  _build_expat
  _build_pcre
  _build_ncurses
  _build_readline
  _build_lua
  _build_apr
  _build_aprutil
  _build_httpd

  _build_bzip
  _build_libjpeg
  _build_libpng
  _build_freetype
  _build_curl
  _build_libmcrypt
  _build_gmp
  _build_libxslt
  _build_bdb
  _build_mysql
  _build_php

  _build_defaults
  _build_certificates
  _package
}
