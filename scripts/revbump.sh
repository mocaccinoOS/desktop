#!/bin/bash
# Author: Ettore Di Giacinto <mudler@mocaccino.org>
# Author: Joost Ruis <joost.ruis@mocaccino.org>
# Automatic revbump of a package
# Needs yq3 and jq
# To use it in the container, run it with:
# ./scripts/run.sh revbump.sh layers/X

PKG_LIST=$(luet tree pkglist -o json)
REVBUMP_CHAR="${REVBUMP_CHAR:-+}"

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

    IFS=/ read -a package <<< "$i"

    path=$(echo "$PKG_LIST" | jq -r ".packages[] | select(.name==\"${package[1]}\" and .category==\"${package[0]}\").path")

    # Skip ignored paths
    if is_ignored "$path"; then
        echo "Skipping $i (ignored path: $path)"
        return
    fi

    REVDEPYQ_ARGS=
    deffile=$path/definition.yaml
    if [ -e "$path/collection.yaml" ]; then
        index=$(yq r "$path/collection.yaml" -j | jq ".packages | map(.name==\"${package[1]}\" and .category==\"${package[0]}\") | index(true)")
        REVDEPYQ_ARGS="packages[$index]."
        deffile="$path/collection.yaml"
    fi

    ver=$(yq r "$deffile" "${REVDEPYQ_ARGS}version")
    revver=1

    if echo "$ver" | grep -q "\\${REVBUMP_CHAR}.*\\${REVBUMP_CHAR}" || echo "$ver" | grep -q "\\${REVBUMP_CHAR}" ; then
        l_ver=${ver%${REVBUMP_CHAR}*}
        revver=${ver/$l_ver${REVBUMP_CHAR}/}
        revver=$((revver+1))
    fi

    ver=${ver%${REVBUMP_CHAR}*}
    ver="${ver}${REVBUMP_CHAR}${revver}"

    echo "Revbump $i at $ver"

    yq w -i "$deffile" "${REVDEPYQ_ARGS}version" "$ver"
}

for i in $(luet tree pkglist -b -m "$1" --revdeps); do
    echo "$i"
    reverse_bump "$i"
done