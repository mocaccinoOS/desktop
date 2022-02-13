#!/bin/bash
# Author: Ettore Di Giacinto <mudler@mocaccino.org>
# Automatic revbump of a package
# Needs yq3 and jq
# To use it in the container, run it with:
# ./scripts/run.sh revbump.sh layers/X

PKG_LIST=$(luet tree pkglist -o json)
REVBUMP_CHAR="${REVBUMP_CHAR:-+}"

reverse_bump() {
    local i="$1"

    IFS=/ read -a package <<< $i

    path=$(echo "$PKG_LIST" | jq -r ".packages[] | select(.name==\"${package[1]}\" and .category==\"${package[0]}\").path")

    REVDEPYQ_ARGS=
    deffile=$path/definition.yaml
    if [ -e "$path/collection.yaml" ]; then
        index=$(yq r $path/collection.yaml -j | jq ".packages | map(.name==\"${package[1]}\" and .category==\"${package[0]}\") | index(true)")
        REVDEPYQ_ARGS="packages[$index]."
        deffile="$path/collection.yaml"
    fi

    ver=$(yq r $deffile "${REVDEPYQ_ARGS}version")
    revver=1

    if echo "$ver" | grep -q "\\${REVBUMP_CHAR}.*\\${REVBUMP_CHAR}" || echo "$ver" | grep -q "\\${REVBUMP_CHAR}" ; then
        l_ver=${ver%${REVBUMP_CHAR}*}
        revver=${ver/$l_ver${REVBUMP_CHAR}/}
        revver=$((revver+1))
    fi
    ver=${ver%${REVBUMP_CHAR}*}
    ver="${ver}${REVBUMP_CHAR}${revver}"

    echo "Revbump $i at $ver"

    yq w -i $deffile "${REVDEPYQ_ARGS}version" "$ver"
} 
  
for i in $(luet tree pkglist -b -m $1 --revdeps); do
    reverse_bump "$i"
done
