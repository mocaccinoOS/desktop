# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3

DESCRIPTION="Collection of Cinnamon Spices extensions (optional via USE flags)"
HOMEPAGE="https://github.com/linuxmint/cinnamon-spices-extensions"
EGIT_REPO_URI="https://github.com/linuxmint/cinnamon-spices-extensions.git"
EGIT_BRANCH="master"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="+screenshot +transparent-panels +tiling"
RDEPEND=">=gnome-extra/cinnamon-6.4"

src_install() {
    if use screenshot; then
        local ext="cinnamon-screenshot@hilyxx"
        insinto /usr/share/cinnamon/extensions/${ext}
        doins -r "${S}/${ext}/files/${ext}"/*
    fi

    if use transparent-panels; then
        local ext="transparent-panels@raresv"
        insinto /usr/share/cinnamon/extensions/${ext}
        doins -r "${S}/${ext}/files/${ext}"/*
    fi

    if use tiling; then
        local ext="tiling@odan"
        insinto /usr/share/cinnamon/extensions/${ext}
        doins -r "${S}/${ext}/files/${ext}"/*
    fi
}