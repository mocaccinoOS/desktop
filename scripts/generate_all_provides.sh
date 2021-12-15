#!/bin/bash

PKG_LIST=$(luet tree pkglist -o json)
export GENERATE_PROVIDES=true

for i in $(echo "$PKG_LIST" | jq -rc '.packages[]'); do

    PACKAGE_PATH=$(echo "$i" | jq -r ".path")
    PACKAGE_NAME=$(echo "$i" | jq -r ".name")
    PACKAGE_CATEGORY=$(echo "$i" | jq -r ".category")
    PACKAGE_VERSION=$(echo "$i" | jq -r ".version")
    
    # Skip buildbase
    if [ "$PACKAGE_CATEGORY" == "buildbase" ]; then
        continue
    fi
    # Skip images/portage
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "images/portage" ]; then
        continue
    fi
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "layers/gentoo-portage" ]; then
        continue
    fi
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "images/stage3" ]; then
        continue
    fi
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "gentoo/stage3" ]; then
        continue
    fi
    # Skip kernel-modules/sources, it is a collection and lacks a definition.yaml
    if [ "$PACKAGE_CATEGORY/$PACKAGE_NAME" == "kernel-modules/sources" ]; then
        continue
    fi
    echo "===== Generating provides for package $PACKAGE_CATEGORY/$PACKAGE_NAME ====="
    ./scripts/package_list.sh "$PACKAGE_CATEGORY/$PACKAGE_NAME"
    docker images --filter='reference=quay.io/mocaccino/desktop' --format='{{.Repository}}:{{.Tag}}' | xargs -r docker rmi
done
