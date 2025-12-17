#!/bin/bash
# Set compiler FIRST
export CC=gcc-${GCC_VERSION}
export CXX=g++-${GCC_VERSION}
export HOSTCC=gcc-${GCC_VERSION}
export HOSTCXX=g++-${GCC_VERSION}

set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
wget https://cdn.kernel.org/pub/linux/kernel/v${PACKAGE_VERSION:0:1}.x/${KERNEL_TYPE}-${PACKAGE_VERSION}.tar.xz -O kernel.tar.xz
tar xvJf kernel.tar.xz
mv ${KERNEL_TYPE}-${PACKAGE_VERSION} ${KERNEL_TYPE}
cp -rfv mocaccino-$ARCH.config ${KERNEL_TYPE}/.config
cd ${KERNEL_TYPE}

# --- Apply Bug 220484 patch ---
# PATCH_FILE="../patches/0001-net-ipv4-route-reset-fi-broadcast.patch"
# if [ -f "$PATCH_FILE" ]; then
#     echo "Applying network regression fix (Bug 220484)..."
#     patch -p1 < "$PATCH_FILE"
# else
#     echo "Warning: Patch file not found: $PATCH_FILE"
# fi

# Verify compiler before config generation
echo "=== Compiler Check ==="
${CC} --version
echo "======================"

# Clean any cached compiler detection
make clean

make olddefconfig
touch /etc/passwd
chmod 644 /etc/passwd
echo "root:x:0:0:root:/root:/bin/sh" > /etc/passwd
