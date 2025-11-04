#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}

# Download and extract the kernel source
wget "https://cdn.kernel.org/pub/linux/kernel/v${PACKAGE_VERSION:0:1}.x/${KERNEL_TYPE}-${PACKAGE_VERSION}.tar.xz" -O kernel.tar.xz
tar xvJf kernel.tar.xz
mv "${KERNEL_TYPE}-${PACKAGE_VERSION}" "${KERNEL_TYPE}"
cp -rfv "mocaccino-${ARCH}.config" "${KERNEL_TYPE}/.config"
cd "${KERNEL_TYPE}"

# --- Apply Bug 220484 patch ---
# PATCH_FILE="../patches/0001-net-ipv4-route-reset-fi-broadcast.patch"
# if [ -f "$PATCH_FILE" ]; then
#     echo "Applying network regression fix (Bug 220484)..."
#     patch -p1 < "$PATCH_FILE"
# else
#     echo "Warning: Patch file not found: $PATCH_FILE"
# fi

# --- Apply Gentoo genpatches ---
GENPATCH_VER=6.17-9
GENPATCHDIR=../genpatches

mkdir -p "${GENPATCHDIR}"

# Download and extract Gentoo patches only if not already present
if [ -z "$(ls -A ${GENPATCHDIR}/*.patch 2>/dev/null)" ]; then
    wget -q "https://dev.gentoo.org/~alicef/genpatches/tarballs/genpatches-${GENPATCH_VER}.base.tar.xz"
    tar -xf "genpatches-${GENPATCH_VER}.base.tar.xz" -C "${GENPATCHDIR}"
fi

echo "Applying Gentoo patches from ${GENPATCHDIR}..."
set +x
for PATCH in ${GENPATCHDIR}/*.patch; do
    echo "Applying ${PATCH}"
    if patch -p1 --forward < "${PATCH}" > patch.log 2>&1; then
        echo "Applied successfully"
    elif grep -q "Reversed (or previously applied)" patch.log; then
        echo "Already applied, skipping"
    else
        echo "Patch failed! See patch.log for details"
        cat patch.log
        exit 1
    fi
done
set -x

echo "All patches processed successfully."

# --- Stop here for testing (remove or comment out when done) ---
exit 0

# --- Continue kernel preparation ---
make olddefconfig
touch /etc/passwd
chmod 644 /etc/passwd
echo "root:x:0:0:root:/root:/bin/sh" > /etc/passwd
