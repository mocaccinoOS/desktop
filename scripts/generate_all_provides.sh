#!/bin/bash

PKG_LIST=$(luet tree pkglist -o json)
export GENERATE_PROVIDES=true

for i in $(echo "$PKG_LIST" | jq -rc '.packages[]'); do

    PACKAGE_PATH=$(echo "$i" | jq -r ".path")
    PACKAGE_NAME=$(echo "$i" | jq -r ".name")
    PACKAGE_CATEGORY=$(echo "$i" | jq -r ".category")
    PACKAGE_VERSION=$(echo "$i" | jq -r ".version")

    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "layer/gentoo-stage3" ]; then
        continue
    fi
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "virtual/python" ]; then
        continue
    fi
    # Skip dev-lang/python too. It is provided by virtual/python
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "dev-lang/python" ]; then
        continue
    fi
    # Skip images/portage
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "images/portage" ]; then
        continue
    fi
    echo "===== Generating provides for package $PACKAGE_CATEGORY/$PACKAGE_NAME ====="
    ./scripts/package_list.sh "$PACKAGE_CATEGORY/$PACKAGE_NAME"
    docker images --filter='reference=quay.io/mocaccinocache/desktop' --format='{{.Repository}}:{{.Tag}}' | xargs -r docker rmi
done
