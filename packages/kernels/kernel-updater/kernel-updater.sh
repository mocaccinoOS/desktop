#!/bin/bash
set -e

ALL_KERNELS=$(luet search --installed kernel --output json | jq -r '.packages[] | select( .category == "kernel" ) | [.category, .name] | join("/")')
MOCACCINO_KERNEL_PREFIX="${MOCACCINO_KERNEL_PREFIX:-mocaccino}"

MOCACCINO_RELEASE=$(cat /etc/mocaccino/release)
MOCACCINO_TARGET=${MOCACCINO_TARGET:-/}

export LUET_NOLOCK=true
generate_micro_initramfs() {
    echo "Generating initramfs and grub setup"

    BOOTDIR=/boot
    CURRENT_KERNEL=$(ls ${MOCACCINO_TARGET}$BOOTDIR/kernel-*)

    # Try to grab current kernel package name, excluding modules
    CURRENT_KERNEL_PACKAGE_NAME=$(luet search --installed kernel --output json | jq -r '.packages[] | select( .category == "kernel" ) | select( .name | test("modules") | not).name')
    MINIMAL_NAME="${CURRENT_KERNEL_PACKAGE_NAME/full/minimal}"
    export INITRAMFS_PACKAGES="${INITRAMFS_PACKAGES:-utils/busybox kernel/$MINIMAL_NAME system/mocaccino-init system/mocaccino-live-boot init/mocaccino-skel system/kmod}"

    export KERNEL_GRUB=${CURRENT_KERNEL/${BOOTDIR}/}
    export INITRAMFS=${CURRENT_KERNEL/kernel/initramfs}
    export INITRAMFS_GRUB=${INITRAMFS/${BOOTDIR}/}

    luet geninitramfs "${INITRAMFS_PACKAGES}"
    pushd ${MOCACCINO_TARGET}/boot/
    rm -rf Initrd bzImage
    ln -s ${KERNEL_GRUB#/} bzImage
    ln -s ${INITRAMFS_GRUB#/} Initrd
    popd

    mkdir -p ${MOCACCINO_TARGET}/boot/grub

    root=$(cat ${MOCACCINO_TARGET}/boot/grub/grub.cfg | grep -Eo "root=(.*)")
    cat > ${MOCACCINO_TARGET}/boot/grub/grub.cfg << EOF
set default=0
set timeout=10
set gfxmode=auto
set gfxpayload=keep
insmod all_video
insmod gfxterm
menuentry "MocaccinoOS" {
    linux /$KERNEL_GRUB ${root}
    initrd /$INITRAMFS_GRUB
}
EOF

    GRUB_TARGET=
    if [ -e "/sys/firmware/efi" ]; then
        GRUB_TARGET="--target=x86_64-efi --efi-dir=/boot/efi"
    fi
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${root}\"" > $MOCACCINO_TARGET/etc/default/grub
    # grub-mkconfig -o /boot/grub/grub.cfg
    install_dev=${root/root=/}
    install_dev=$(printf '%s' "$install_dev" | tr -d '0123456789')
    grub-install ${GRUB_TARGET} $install_dev
}

generate_dracut_initramfs() {
  local kernel=$1
  local md_args="--force"
  local version=""

  echo "Generating initramfs and update grub setup"

  if [ -z "$kernel" ] ; then
    md_args="$md_args --rebuild-all"
  else
    # Retrieve version of the kernel
    if [[ "$kernel" == *lts* ]] ; then
      version=$(luet search --installed kernel --output json | jq  ".packages[] | select ( .category == \"kernel\" and .name == \"${MOCACCINO_KERNEL_PREFIX}-lts-modules\" ) | .version")
    else
      version=$(luet search --installed kernel --output json | jq  ".packages[] | select ( .category == \"kernel\" and .name == \"${MOCACCINO_KERNEL_PREFIX}-modules\" ) | .version")
    fi
    version=${version%\+*}
    md_args="$md_args -r ${version}"
  fi

  mocaccino-dracut $md_args

  # TODO: Fix initialization of bzImage, Initrd. Is it used correctly?
  grub-mkconfig -o ${MOCACCINO_TARGET}/boot/grub/grub.cfg
}

case "$MOCACCINO_RELEASE" in
  "micro")
    generate_micro_initramfs
    ;;
  "micro-embedded"|"desktop-embedded")
    echo "Nothing to do"
    ;;
  "desktop")
    generate_dracut_initramfs
    ;;
  *)
    echo "The release $MOCACCINO_RELEASE is unsupported."
    exit 1
    ;;
esac

exit 0
