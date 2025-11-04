#!/bin/bash
set -e
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
wget https://cdn.kernel.org/pub/linux/kernel/v${PACKAGE_VERSION:0:1}.x/${KERNEL_TYPE}-${PACKAGE_VERSION}.tar.xz -O kernel.tar.xz
tar xvJf kernel.tar.xz
mv ${KERNEL_TYPE}-${PACKAGE_VERSION} ${KERNEL_TYPE}
cp -rfv mocaccino-$ARCH.config ${KERNEL_TYPE}/.config
cd ${KERNEL_TYPE}
# --- Apply Gentoo genpatches, using genpatches/ directory ---
GENPATCH_VER="6.17-9"
PATCHDIR="../genpatches"
mkdir -p "${PATCHDIR}"
if [ -z "$(ls -A ${PATCHDIR}/*.patch 2>/dev/null)" ]; then
    wget -q "https://dev.gentoo.org/~alicef/genpatches/tarballs/genpatches-${GENPATCH_VER}.base.tar.xz"
    tar -xf "genpatches-${GENPATCH_VER}.base.tar.xz" -C "${PATCHDIR}"
fi
PATCH_SUCCESS=0
PATCH_SKIPPED=0
PATCH_FAILED=0

for PATCH in ${PATCHDIR}/*.patch; do
    echo "=========================================="
    echo "Processing: $(basename ${PATCH})"
    
    # Try to apply the patch with dry-run and capture output
    PATCH_OUTPUT=$(patch -p1 --forward --dry-run < "${PATCH}" 2>&1 || true)
    
    if echo "$PATCH_OUTPUT" | grep -q "FAILED\|can't find file\|malformed patch"; then
        echo "✗ FAILED: Patch cannot be applied (missing files or conflicts)"
        echo "$PATCH_OUTPUT"
        ((PATCH_FAILED++))
        exit 1
    elif echo "$PATCH_OUTPUT" | grep -q "Reversed (or previously applied) patch detected"; then
        echo "⊙ SKIPPED: Patch already applied"
        ((PATCH_SKIPPED++))
    elif patch -p1 --forward --dry-run < "${PATCH}" &>/dev/null; then
        # Patch can be cleanly applied
        if patch -p1 --forward < "${PATCH}" &>/dev/null; then
            echo "✓ SUCCESS: Patch applied successfully"
            ((PATCH_SUCCESS++))
        else
            echo "✗ FAILED: Patch application failed"
            patch -p1 --forward < "${PATCH}" || true  # Show the error
            ((PATCH_FAILED++))
            exit 1
        fi
    else
        echo "✗ FAILED: Patch cannot be applied"
        echo "$PATCH_OUTPUT"
        ((PATCH_FAILED++))
        exit 1
    fi
done

echo "=========================================="
echo "Patch Summary:"
echo "  Successfully applied: ${PATCH_SUCCESS}"
echo "  Already applied (skipped): ${PATCH_SKIPPED}"
echo "  Failed: ${PATCH_FAILED}"
echo "=========================================="

if [ ${PATCH_FAILED} -gt 0 ]; then
    echo "ERROR: Some patches failed to apply. Check .rej files for details."
    exit 1
fi

# --- Custom patches shipped in patches/ directory ---
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