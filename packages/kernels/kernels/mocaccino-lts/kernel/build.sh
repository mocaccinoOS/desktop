#!/bin/bash
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
mkdir -p output/boot
pushd ${KERNEL_TYPE}

# $ARCH can't be amd64 here, x86_64 is used here
if [ $ARCH == "amd64" ]; then
  ARCH = "x86_64"
fi

make -j$(nproc --ignore=1) KBUILD_BUILD_VERSION="$PACKAGE_VERSION-Mocaccino"

if [[ -L "arch/${ARCH}/boot/bzImage" ]]; then
   cp -rfv $(readlink -f "arch/${ARCH}/boot/bzImage") ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
else
   cp -rfv arch/${ARCH}/boot/bzImage ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
fi
