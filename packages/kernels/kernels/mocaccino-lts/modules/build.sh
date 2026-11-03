#!/bin/bash

PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
outdir="/luetbuild/modules"
mkdir -p $outdir/boot
pushd linux

# $ARCH can't be amd64 here, x86_64 is used here
if [ $ARCH == "amd64" ]; then
  ARCH="x86_64"
fi

if [ ! -e "arch/x86/boot/bzImage" ]; then
    cp -rfv ../output/* arch/x86/boot/bzImage || true
fi

# Install kernel modules with debug symbols stripped.
# INSTALL_MOD_STRIP=1 uses --strip-debug.
make -j"$(nproc --ignore=1)" \
    modules_install install \
    INSTALL_MOD_PATH="$outdir/usr" \
    INSTALL_MOD_STRIP=1 \
    INSTALL_PATH="$outdir/boot"

# Remove build/source symlinks from the installed modules.
rm -f "$outdir"/usr/lib/modules/**/build \
    "$outdir"/usr/lib/modules/**/source

popd

mv $outdir/boot/config-$PACKAGE_VERSION-${SUFFIX} \
  $outdir/boot/config-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}
mv $outdir/boot/System.map-$PACKAGE_VERSION-${SUFFIX} \
  $outdir/boot/System.map-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}
mv $outdir/boot/vmlinuz-$PACKAGE_VERSION-${SUFFIX} \
  $outdir/boot/vmlinuz-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}
