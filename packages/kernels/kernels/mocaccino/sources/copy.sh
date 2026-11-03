#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}

du -sh ${KERNEL_TYPE}

# Strip debug info from objects and modules, keep host tools untouched
find ${KERNEL_TYPE} -type f \( -name '*.o' -o -name '*.ko' \) \
  -not -path "${KERNEL_TYPE}/scripts/*" -not -path "${KERNEL_TYPE}/tools/*" \
  -print0 | xargs -0 -r -P"$(nproc)" -n64 strip --strip-debug
strip --strip-debug ${KERNEL_TYPE}/vmlinux

du -sh ${KERNEL_TYPE}

mkdir -p /luetbuild/sources/usr/src/
mv ${KERNEL_TYPE} /luetbuild/sources/usr/src/${KERNEL_TYPE}-${PACKAGE_VERSION}-${SUFFIX}
