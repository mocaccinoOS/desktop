#!/bin/bash
set -e

# Use PACKAGE_VERSION from environment, or accept as argument
KERNEL_VERSION="${1:-${PACKAGE_VERSION}}"
# Strip any +suffix from version (like build.sh does)
KERNEL_VERSION="${KERNEL_VERSION%\+*}"

# Extract major.minor version (e.g., "6.18" from "6.18.5")
MAJOR_MINOR=$(echo ${KERNEL_VERSION} | cut -d. -f1-2)

PATCHES_DIR="$(dirname "$0")/patches"
mkdir -p "${PATCHES_DIR}"

echo "Fetching Gentoo patches for kernel ${KERNEL_VERSION} (branch ${MAJOR_MINOR})..."

cd "${PATCHES_DIR}"

# Check if patches already exist
if [ -f ".fetched-${MAJOR_MINOR}" ]; then
    echo "Patches for ${MAJOR_MINOR} already fetched, skipping download..."
else
    # Clean old patches
    rm -f *.patch .fetched-*

    # Clone the specific kernel version branch from Gentoo's linux-patches repo
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf ${TEMP_DIR}" EXIT

    echo "Cloning Gentoo linux-patches repository (branch ${MAJOR_MINOR})..."

    # Try to clone the specific branch
    if git clone --depth 1 --branch ${MAJOR_MINOR} \
        https://anongit.gentoo.org/git/proj/linux-patches.git \
        "${TEMP_DIR}" 2>/dev/null; then
        
        echo "Successfully cloned ${MAJOR_MINOR} branch"
        
        # Copy all patch files
        if [ -d "${TEMP_DIR}" ]; then
            find "${TEMP_DIR}" -name "*.patch" -exec cp {} . \;
            
            # Remove version upgrade patches (1xxx series)
            rm -f 1[0-9][0-9][0-9]_linux-*.patch
            echo "Removed version upgrade patches (1xxx series)"
            
            patch_count=$(ls -1 *.patch 2>/dev/null | wc -l)
            
            if [ ${patch_count} -gt 0 ]; then
                echo "Downloaded ${patch_count} patches from Gentoo git"
                touch ".fetched-${MAJOR_MINOR}"
            fi
        fi
    else
        echo "Warning: No patches found for kernel ${MAJOR_MINOR} in Gentoo's repository"
        echo "Check available branches at: https://gitweb.gentoo.org/proj/linux-patches.git/"
        echo "Continuing without Gentoo patches..."
    fi
fi

# Now apply the patches
echo "Applying kernel patches..."
patch_count=0
failed_count=0

for patch in *.patch; do
    [ -f "$patch" ] || continue
    
    echo "Applying: $patch"
    if patch -p1 -d ../linux < "$patch"; then
        patch_count=$((patch_count + 1))
    else
        echo "Warning: Failed to apply $patch, continuing..."
        failed_count=$((failed_count + 1))
    fi
done

if [ ${patch_count} -gt 0 ]; then
    echo "Successfully applied ${patch_count} patches"
    if [ ${failed_count} -gt 0 ]; then
        echo "Warning: ${failed_count} patches failed to apply"
    fi
else
    echo "No patches to apply"
fi