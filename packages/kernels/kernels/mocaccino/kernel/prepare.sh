#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
wget https://cdn.kernel.org/pub/linux/kernel/v${PACKAGE_VERSION:0:1}.x/${KERNEL_TYPE}-${PACKAGE_VERSION}.tar.xz -O kernel.tar.xz
tar xvJf kernel.tar.xz
mv ${KERNEL_TYPE}-${PACKAGE_VERSION} ${KERNEL_TYPE}
cp -rfv mocaccino-$ARCH.config ${KERNEL_TYPE}/.config
cd ${KERNEL_TYPE}

# --- Apply Gentoo genpatches ---
GENPATCH_VER="6.17-9"
PATCHDIR="../patches"

mkdir -p "${PATCHDIR}"

if [ -z "$(ls -A ${PATCHDIR}/*.patch 2>/dev/null)" ]; then
    wget -q "https://dev.gentoo.org/~alicef/genpatches/tarballs/genpatches-${GENPATCH_VER}.base.tar.xz"
    tar -xf "genpatches-${GENPATCH_VER}.base.tar.xz" -C "${PATCHDIR}"
fi

for PATCH in ${PATCHDIR}/*.patch; do
    echo "Applying ${PATCH}"
    patch -p1 --forward < "${PATCH}" || exit 1
done

# --- Custom patches shipped in patches directory ---

# --- Apply Bug 220484 patch ---
# PATCH_FILE="../patches/0001-net-ipv4-route-reset-fi-broadcast.patch"
# if [ -f "$PATCH_FILE" ]; then
#     echo "Applying network regression fix (Bug 220484)..."
#     patch -p1 < "$PATCH_FILE"
# else
#     echo "Warning: Patch file not found: $PATCH_FILE"
# fi

make olddefconfig
touch /etc/passwd
chmod 644 /etc/passwd
echo "root:x:0:0:root:/root:/bin/sh" > /etc/passwd
