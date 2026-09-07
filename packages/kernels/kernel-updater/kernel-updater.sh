#!/bin/bash
set -e

export CHOST="${CHOST:-x86_64-pc-linux-gnu}"

ALL_KERNELS=$(luet search --installed kernel --output json | jq -r '.packages[] | select( .category == "kernel" ) | [.category, .name] | join("/")')
MOCACCINO_KERNEL_PREFIX="${MOCACCINO_KERNEL_PREFIX:-mocaccino}"

MOCACCINO_RELEASE=$(cat /etc/mocaccino/release)
MOCACCINO_TARGET=${MOCACCINO_TARGET:-/}

export LUET_NOLOCK=true

cleanup_stale_initramfs() {
    local pretend=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --pretend)
                pretend=1
                ;;
            *)
                echo "cleanup_stale_initramfs: unknown argument $1" 1>&2
                return 1
                ;;
        esac
        shift
    done

    if [ "$pretend" = 1 ]; then
        echo "Checking for stale initramfs images (--pretend — nothing will be deleted)"
    else
        echo "Checking for stale initramfs images"
    fi

    # 1. Refuse to evaluate cleanup if we can't positively confirm the new
    #    initramfs is a real, non-empty, resolvable file.
    local new_initramfs="${MOCACCINO_TARGET%/}${INITRAMFS}"
    if [ ! -s "$new_initramfs" ]; then
        echo "New initramfs missing or empty — skipping cleanup check this run"
        return 0
    fi

    # 2. Refuse to evaluate cleanup if the installed-kernel query looks
    #    empty/broken. An empty/failed query must never be read as
    #    "nothing is installed".
    local installed_versions
    installed_versions=$(luet search --installed kernel --output json \
        | jq -r '.packages[] | select(.category=="kernel") | select(.name | test("modules") | not) | .version' \
        | sed -E 's/\+.*//')
    if [ -z "$installed_versions" ]; then
        echo "Could not confirm installed kernel list — skipping cleanup check this run"
        return 0
    fi

    # Only ever consider files matching the *exact* naming convention
    # mocaccino-dracut/kernel-updater use for official "vanilla" kernels.
    # Anything else — custom kernels, different ktypes (zen, hardened,
    # self-built, etc.) — is never touched, never even evaluated.
    local ktype="vanilla"
    local arch="${MOC_ARCH:-$(uname -m)}"

    local candidates=()
    for f in "${MOCACCINO_TARGET%/}${BOOTDIR}"/initramfs-${ktype}-${arch}-*-mocaccino; do
        [ -e "$f" ] || continue
        [ "$f" = "$new_initramfs" ] && continue
        candidates+=("$f")
    done

    # Only sort if there's actually something to sort — "ls -tr" with no
    # arguments lists the current working directory, not "nothing", so an
    # empty candidates array must never reach `ls` unguarded (this is the
    # common case on a fresh install / ISO build chroot with one kernel).
    if [ "${#candidates[@]}" -gt 0 ]; then
        IFS=$'\n' candidates=($(ls -tr "${candidates[@]}" 2>/dev/null))
        unset IFS
    fi

    # Always keep the single most recent non-current one as a manual
    # rescue fallback, no matter what luet reports.
    local keep_fallback="${candidates[-1]:-}"

    local found_any=0
    for f in "${candidates[@]}"; do
        [ "$f" = "$keep_fallback" ] && continue

        local ver
        ver=$(basename "$f" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

        # exact match only — no substring false-positives
        if printf '%s\n' "$installed_versions" | grep -qxF "$ver"; then
            continue   # still installed, never touch
        fi

        found_any=1
        if [ "$pretend" = 1 ]; then
            echo "[WOULD REMOVE] $f"
        else
            echo "Removing stale $f"
            rm -f -- "$f" || true   # cleanup is best-effort, never fails the update
        fi
    done

    if [ "$found_any" = 0 ]; then
        echo "No stale initramfs images found."
    fi
}

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

    cleanup_stale_initramfs

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

    BOOTDIR=/boot

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

    # Figure out which initramfs was just (re)built so cleanup can exclude it.
    CURRENT_KERNEL=$(ls ${MOCACCINO_TARGET}$BOOTDIR/kernel-* 2>/dev/null | head -1)
    if [ -n "$CURRENT_KERNEL" ]; then
        export INITRAMFS=${CURRENT_KERNEL/kernel/initramfs}
        INITRAMFS=${INITRAMFS/${MOCACCINO_TARGET}/}
        cleanup_stale_initramfs
    else
        echo "Could not determine current kernel file — skipping cleanup check this run"
    fi

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