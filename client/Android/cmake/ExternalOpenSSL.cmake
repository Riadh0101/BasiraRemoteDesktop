include(ExternalProject)
include(DepVersions)

# Map ANDROID_ABI to OpenSSL architecture names
if(ANDROID_ABI STREQUAL "arm64-v8a")
  set(OSSL_ARCH "android-arm64")
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
  set(OSSL_ARCH "android-arm")
elseif(ANDROID_ABI STREQUAL "x86_64")
  set(OSSL_ARCH "android-x86_64")
elseif(ANDROID_ABI STREQUAL "x86")
  set(OSSL_ARCH "android-x86")
elseif(ANDROID_ABI STREQUAL "riscv64")
  set(OSSL_ARCH "android-riscv64")
else()
  message(FATAL_ERROR "ExternalOpenSSL: unsupported ABI '${ANDROID_ABI}'")
endif()

find_program(GIT_PERL NAMES perl PATHS "C:/Program Files/Git/usr/bin" NO_DEFAULT_PATH)
if(NOT GIT_PERL)
  find_package(Perl REQUIRED)
  set(GIT_PERL "${PERL_EXECUTABLE}")
endif()
get_filename_component(GIT_PERL_DIR "${GIT_PERL}" DIRECTORY)

set(NDK_TOOLCHAIN_BIN "${NDK_ROOT}/toolchains/llvm/prebuilt/${NDK_HOST_PLATFORM}/bin")

ExternalProject_Add(
  openssl
  DOWNLOAD_EXTRACT_TIMESTAMP OFF
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/external/openssl
  BINARY_DIR ${CMAKE_BINARY_DIR}/external/openssl
  URL https://github.com/openssl/openssl/releases/download/${OPENSSL_VERSION}/${OPENSSL_VERSION}.tar.gz
  URL_HASH ${OPENSSL_HASH}
  PATCH_COMMAND ${CMAKE_COMMAND} -DOPENSSL_SRC=<SOURCE_DIR> -P ${CMAKE_CURRENT_LIST_DIR}/PatchOpenSSL.cmake
  LIST_SEPARATOR |
  CONFIGURE_COMMAND
    ${CMAKE_COMMAND} -E env
    --modify PATH=path_list_prepend:${NDK_TOOLCHAIN_BIN}
    --modify PATH=path_list_prepend:${GIT_PERL_DIR}
    MSYS2_ENV_CONV_EXCL=PERL5LIB
    PERL5LIB=/c/Users/Administrator/.local/perl5/lib
    ANDROID_NDK=${NDK_ROOT} ANDROID_NDK_ROOT=${NDK_ROOT} ANDROID_NDK_HOME=${NDK_ROOT} CC=clang
    "${GIT_PERL}" <SOURCE_DIR>/Configure ${OSSL_ARCH} shared no-tests no-apps no-docs
    -U__ANDROID_API__ -D__ANDROID_API__=${NDK_API_LEVEL} --prefix=${DEPS_INSTALL_DIR} --libdir=${CMAKE_INSTALL_LIBDIR}
  BUILD_COMMAND
    ${CMAKE_COMMAND} -E env
    --modify PATH=path_list_prepend:${NDK_TOOLCHAIN_BIN}
    --modify PATH=path_list_prepend:${GIT_PERL_DIR}
    MSYS2_ENV_CONV_EXCL=PERL5LIB
    PERL5LIB=/c/Users/Administrator/.local/perl5/lib
    ANDROID_NDK=${NDK_ROOT} ANDROID_NDK_ROOT=${NDK_ROOT} ANDROID_NDK_HOME=${NDK_ROOT}
    make -j4 SHLIB_EXT=.so build_libs
  INSTALL_COMMAND
    ${CMAKE_COMMAND} -E env
    --modify PATH=path_list_prepend:${NDK_TOOLCHAIN_BIN}
    --modify PATH=path_list_prepend:${GIT_PERL_DIR}
    MSYS2_ENV_CONV_EXCL=PERL5LIB
    PERL5LIB=/c/Users/Administrator/.local/perl5/lib
    ANDROID_NDK=${NDK_ROOT} ANDROID_NDK_ROOT=${NDK_ROOT} ANDROID_NDK_HOME=${NDK_ROOT}
    make -j4 SHLIB_EXT=.so install_sw
)

ExternalProject_Add_Step(
  openssl patch_makefile
  COMMAND python ${CMAKE_CURRENT_LIST_DIR}/patch_openssl_makefile.py <BINARY_DIR>
  DEPENDEES configure
  DEPENDERS build
)

ExternalProject_Add_Step(
  openssl copy_modules
  COMMAND ${CMAKE_COMMAND} -DSRC=${DEPS_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/ossl-modules
                           -DDEST=${DEPS_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}
                           -P ${CMAKE_CURRENT_LIST_DIR}/CopyIfDirExists.cmake
  DEPENDEES install
)
