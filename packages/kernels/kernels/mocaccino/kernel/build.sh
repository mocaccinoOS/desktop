#!/bin/bash
echo "Using CC=$(which ${CC})"
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
MAJOR_VERSION=$(awk -F. '{print $1"."$2}' <<< $PACKAGE_VERSION)
mkdir -p output/boot
pushd ${KERNEL_TYPE}

make -j$(nproc --ignore=1) KBUILD_BUILD_VERSION="$PACKAGE_VERSION-Mocaccino"

# $ARCH can't be amd64 here, x86_64 is used here
if [ $ARCH == "amd64" ]; then
  ARCH = "x86_64"
fi

if [[ -L "arch/${ARCH}/boot/bzImage" ]]; then
   cp -rfv $(readlink -f "arch/${ARCH}/boot/bzImage") ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
else
   cp -rfv arch/${ARCH}/boot/bzImage ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
fi
