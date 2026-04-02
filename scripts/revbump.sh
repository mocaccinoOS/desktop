#!/bin/bash
# Author: Ettore Di Giacinto <mudler@mocaccino.org>
# Author: Joost Ruis <joost.ruis@mocaccino.org>
# Automatic revbump of a package
# Needs yq3 and jq

set -euo pipefail

REVBUMP_CHAR="${REVBUMP_CHAR:-+}"

# Get clean JSON (avoid luet noise breaking jq)
PKG_LIST=$(luet tree pkglist -o json 2>/dev/null || true)

# Paths to ignore for revbump
IGNORED_PATHS=(
    "packages/apps/edgevpn-gui"
    "packages/apps/fyneterm"
    "packages/apps/golauncher"
    "packages/apps/luet_pm_gui"
    "packages/apps/mos-updater"
    "packages/apps/nodejs"
    "packages/apps/vajo"
    "packages/fonts"
    "packages/devel/gcc-14"
    "packages/devel/linux-headers"
    "packages/layers/pangolin-desktop"
    "packages/layers/trinity"
    "packages/themes"
)

is_ignored() {
    local p="$1"
    for ignore in "${IGNORED_PATHS[@]}"; do
        [[ $p == *"$ignore"* ]] && return 0
    done
    return 1
}

reverse_bump() {
    local i="$1"

    IFS=/ read -r category name <<< "$i"

    path=$(echo "$PKG_LIST" | jq -r \
        ".packages[] | select(.name==\"${name}\" and .category==\"${category}\").path" 2>/dev/null || true)

    # Guard: skip if path not found
    if [ -z "${path:-}" ] || [ "$path" = "null" ]; then
        echo "Skipping $i (no path found)"
        return
    fi

    # Skip ignored paths
    if is_ignored "$path"; then
        echo "Skipping $i (ignored path: $path)"
        return
    fi

    REVDEPYQ_ARGS=
    deffile="$path/definition.yaml"

    if [ -e "$path/collection.yaml" ]; then
        index=$(yq r "$path/collection.yaml" -j | jq \
            ".packages | map(.name==\"${name}\" and .category==\"${category}\") | index(true)")

        if [ "$index" != "null" ]; then
            REVDEPYQ_ARGS="packages[$index]."
            deffile="$path/collection.yaml"
        fi
    fi

    # Guard: file must exist
    if [ ! -f "$deffile" ]; then
        echo "Skipping $i (missing $deffile)"
        return
    fi

    ver=$(yq r "$deffile" "${REVDEPYQ_ARGS}version" 2>/dev/null || true)

    # Guard: version must exist
    if [ -z "${ver:-}" ] || [ "$ver" = "null" ]; then
        echo "Skipping $i (no version found)"
        return
    fi

    revver=1

    if echo "$ver" | grep -q "${REVBUMP_CHAR}"; then
        base="${ver%${REVBUMP_CHAR}*}"
        revver="${ver##*${REVBUMP_CHAR}}"

        # Ensure numeric
        if [[ "$revver" =~ ^[0-9]+$ ]]; then
            revver=$((revver + 1))
        else
            revver=1
        fi
    else
        base="$ver"
    fi

    newver="${base}${REVBUMP_CHAR}${revver}"

    echo "Revbump $i -> $newver"

    yq w -i "$deffile" "${REVDEPYQ_ARGS}version" "$newver"
}

# Proper loop (no word splitting!)
luet tree pkglist -b -m "$1" --revdeps | while read -r i; do
    [ -z "$i" ] && continue
    echo "$i"
    reverse_bump "$i"
done