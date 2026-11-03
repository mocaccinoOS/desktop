#!/bin/bash
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
MAJOR_VERSION=$(awk -F. '{print $1"."$2}' <<< $PACKAGE_VERSION)
mkdir -p output/boot
pushd ${KERNEL_TYPE}

echo "Compiler version check:"
${CC:-gcc} --version
echo "---"

# make -j$(nproc --ignore=1) KBUILD_BUILD_VERSION="$PACKAGE_VERSION-Mocaccino"

# Force compiler on make command line
make -j$(nproc --ignore=1) \
    CC="${CC}" \
    HOSTCC="${HOSTCC}" \
    HOSTCXX="${HOSTCXX}" \
    KBUILD_BUILD_VERSION="$PACKAGE_VERSION-Mocaccino"

# $ARCH can't be amd64 here, x86_64 is used here
if [ $ARCH == "amd64" ]; then
  ARCH="x86_64"
fi

if [[ -L "arch/${ARCH}/boot/bzImage" ]]; then
   cp -rfv $(readlink -f "arch/${ARCH}/boot/bzImage") ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
else
   cp -rfv arch/${ARCH}/boot/bzImage ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
fi

# Strip debug info now so the builder image layer stays small.
# -p keeps timestamps so later make steps (modules_install) don't rebuild.
du -sh .
find . -type f \( -name '*.o' -o -name '*.ko' \) \
  -not -path './scripts/*' -not -path './tools/*' \
  -print0 | xargs -0 -r -P"$(nproc)" -n64 strip --strip-debug -p
strip --strip-debug -p vmlinux
du -sh .