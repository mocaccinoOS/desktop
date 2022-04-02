#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
mkdir -p /luetbuild/sources/usr/src/
mv ${KERNEL_TYPE} /luetbuild/sources/usr/src/${KERNEL_TYPE}-${PACKAGE_VERSION}-${SUFFIX}
