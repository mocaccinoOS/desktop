#!/bin/bash

out="$(luet search -o json | luet filter)"
excludes="${EXCLUDES:-runit|kernel|skopeo|system\/luet|mocaccino-release|default-protect}"

error=

if  echo "$out" | grep -Pv "$excludes" | grep "Duplicate found"; then
    error="Duplicate found"
fi

PKG_LIST=$(luet tree pkglist --tree packages -o json) 

for i in $(echo "$PKG_LIST" | jq -rc '.packages[]'); do
    PACKAGE_PATH=$(echo "$i" | jq -r ".path")
    PACKAGE_NAME=$(echo "$i" | jq -r ".name")
    PACKAGE_CATEGORY=$(echo "$i" | jq -r ".category")
    PACKAGE_VERSION=$(echo "$i" | jq -r ".version")
    PACKAGE_VERSION=${PACKAGE_VERSION//\+/\-}
    PACKAGE=$PACKAGE_NAME-$PACKAGE_CATEGORY-$PACKAGE_VERSION           
    if ! luet util image-exist "quay.io/mocaccino/desktop:$PACKAGE"; then
       echo "$PACKAGE_CATEGORY/$PACKAGE_NAME missing"
       error="missing package"
    fi
    if ! luet util image-exist "quay.io/mocaccino/desktop:$PACKAGE.metadata.yaml"; then
       echo "$PACKAGE_CATEGORY/$PACKAGE_NAME metadata missing"
       error="missing package"
    fi
done        

if [ -n "$error" ]; then
    echo "Failed: $error"
    exit 1
fi
