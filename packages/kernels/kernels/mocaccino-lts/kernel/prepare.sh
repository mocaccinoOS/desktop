#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
wget https://cdn.kernel.org/pub/linux/kernel/v${PACKAGE_VERSION:0:1}.x/${KERNEL_TYPE}-${PACKAGE_VERSION}.tar.xz -O kernel.tar.xz
tar xvJf kernel.tar.xz
mv ${KERNEL_TYPE}-${PACKAGE_VERSION} ${KERNEL_TYPE}
cp -rfv mocaccino-$ARCH.config ${KERNEL_TYPE}/.config
cd ${KERNEL_TYPE}
make olddefconfig
touch /etc/passwd
chmod 644 /etc/passwd
echo "root:x:0:0:root:/root:/bin/sh" > /etc/passwd
