#!/bin/bash

# Loosely based on LFS systemd

set -e

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
fi

TMPFILE=tmp-system

# Create 2gb raw ext4 image file
dd if=/dev/zero of=${TMPFILE} bs=1M count=2048
mkfs.ext4 ${TMPFILE}

# Grab blkid for dm-verity
SYSTEM_PARTITION_UUID=$(blkid ${TMPFILE} | awk '{ print $2 }' | sed -E 's/UUID="(.*)"/\1/g')
export MAKEFLAGS="-j$(nproc)"

# Mount ext4 image
sudo mkdir -p system-mount
LOOP=$(sudo losetup -f)
sudo losetup -f ${TMPFILE}
sudo mount ${LOOP} system-mount/

LFS=$(pwd)/system-mount
LFS_HOST="x86_64-pc-linux-gnu"
LFS_TARGET="aarch64-linux-gnu"

# Create folder structure
sudo mkdir -pv $LFS/{etc,var,tmp} $LFS/usr/{bin,lib,sbin}
sudo ln -sv lib $LFS/usr/lib64

for i in bin lib lib64 sbin; do
  sudo ln -sv usr/$i $LFS/$i
done

# Kernel Headers
DEFCONFIG="rpi_cm4_io_router_defconfig"
KBUILD_BUILD_TIMESTAMP='' make -C ../boot-image/linux ARCH=arm64 CC="ccache clang" LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- ${DEFCONFIG}
KBUILD_BUILD_TIMESTAMP='' sudo make -C ../boot-image/linux ARCH=arm64 CC="ccache clang" LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_HDR_PATH=$LFS/usr headers_install

# Bootstrap packages
cd packages
sudo env LFS_TARGET=$LFS_TARGET LFS_HOST=$LFS_HOST LFS=$LFS ./build.sh
cd -

# Unmount image
sudo umount system-mount
sudo losetup -d ${LOOP}

xz -T0 -e -9 ${TMPFILE}
mv ${TMPFILE}.xz system${DEBUG}.img.xz
