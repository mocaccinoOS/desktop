#!/bin/bash
# Set compiler FIRST
export CC=gcc-${GCC_VERSION}
export CXX=g++-${GCC_VERSION}
export HOSTCC=gcc-${GCC_VERSION}
export HOSTCXX=g++-${GCC_VERSION}

set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
wget -q --show-progress https://cdn.kernel.org/pub/linux/kernel/v${PACKAGE_VERSION:0:1}.x/${KERNEL_TYPE}-${PACKAGE_VERSION}.tar.xz -O kernel.tar.xz
tar xvJf kernel.tar.xz
mv ${KERNEL_TYPE}-${PACKAGE_VERSION} ${KERNEL_TYPE}
cp -rfv mocaccino-$ARCH.config ${KERNEL_TYPE}/.config

# Fetch Gentoo kernel patches BEFORE changing directory
echo "Fetching Gentoo kernel patches for version ${PACKAGE_VERSION}..."
bash fetch-gentoo-patches.sh

cd ${KERNEL_TYPE}

# Apply all patches from ../patches directory, EXCEPT version upgrade patches
PATCHES_DIR="../patches"
if [ -d "${PATCHES_DIR}" ]; then
    echo "Applying kernel patches..."
    patch_count=0
    skipped_count=0
    for patch in "${PATCHES_DIR}"/*.patch; do
        [ -f "$patch" ] || continue
        
        # Skip patches that are kernel version upgrades (1xxx series)
        if [[ "$(basename $patch)" =~ ^1[0-9]{3}_linux-[0-9.]+\.patch$ ]]; then
            echo "Skipping version patch: $(basename $patch)"
            ((skipped_count++))
            continue
        fi
        
        echo "Applying: $(basename $patch)"
        if patch -p1 < "$patch"; then
            ((patch_count++))
        else
            echo "Warning: Failed to apply $(basename $patch), continuing..."
        fi
    done
    echo "Successfully applied ${patch_count} patches (skipped ${skipped_count} version patches)"
else
    echo "No patches directory found at ${PATCHES_DIR}"
fi

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