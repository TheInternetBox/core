#!/bin/bash

set -e

BUILD_TYPE=MinSizeRel
ENABLE_ASSERTIONS=OFF

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
    BUILD_TYPE=RelWithDebInfo
    ENABLE_ASSERTIONS=ON
fi

cd packages/llvm

mkdir -p build
cd build

COMMON_CFLAGS="-O2 -fstack-protector-strong -fPIE -D_FORTIFY_SOURCE=2"

CXX=clang++ CC=clang cmake -G Ninja \
    -DLLVM_ENABLE_PROJECTS='clang;libcxx;libcxxabi;compiler-rt;lld' \
    -DCMAKE_INSTALL_PREFIX=$LFS/tools \
    -DCMAKE_CXX_FLAGS="$COMMON_CFLAGS $TARGET_CFLAGS" \
    -DCMAKE_C_FLAGS="$COMMON_CFLAGS $TARGET_CFLAGS" \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DLLVM_ENABLE_ASSERTIONS=$ENABLE_ASSERTIONS \
    -DLLVM_ENABLE_LTO=ON \
    -DLLVM_BUILD_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_CCACHE_BUILD=ON \
    -DCMAKE_CROSSCOMPILING=ON \
    -DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-linux-gnu \
    -DLLVM_TARGET_ARCH=AArch64 \
    -DLLVM_TARGETS_TO_BUILD=AArch64 \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=AArch64 \
    -DLLVM_PARALLEL_LINK_JOBS=3 \
    ../llvm

# Build
cmake --build .

# Test
cmake --build . --target check-all

# Install
cmake --build . --target install