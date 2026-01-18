#!/bin/bash
set -e

# Use PACKAGE_VERSION from environment, or accept as argument
KERNEL_VERSION="${1:-${PACKAGE_VERSION}}"
# Strip any +suffix from version (like build.sh does)
KERNEL_VERSION="${KERNEL_VERSION%\+*}"

# Gentoo patch versioning (adjust suffix as needed)
GENPATCHES_VERSION="${KERNEL_VERSION}-1"
PATCHES_DIR="$(dirname "$0")/../patches"

mkdir -p "${PATCHES_DIR}"

echo "Fetching Gentoo patches for kernel ${KERNEL_VERSION}..."

cd "${PATCHES_DIR}"

# Check if patches already exist to avoid re-downloading
if [ -f ".fetched-${KERNEL_VERSION}" ]; then
    echo "Patches for ${KERNEL_VERSION} already fetched, skipping..."
    exit 0
fi

# Clean old patches from different versions
rm -f *.patch .fetched-*

# Download genpatches
wget -q "https://dev.gentoo.org/~mpagano/genpatches/tarballs/genpatches-${GENPATCHES_VERSION}.base.tar.xz" || {
    echo "Failed to download genpatches. Check if version exists at:"
    echo "https://dev.gentoo.org/~mpagano/genpatches/tarballs/"
    exit 1
}

# Extract patches
tar xf genpatches-${GENPATCHES_VERSION}.base.tar.xz
rm genpatches-${GENPATCHES_VERSION}.base.tar.xz

# Mark as fetched
touch ".fetched-${KERNEL_VERSION}"

echo "Patches downloaded to ${PATCHES_DIR}"
ls -1 *.patch 2>/dev/null | wc -l | xargs echo "Total patches:"