# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Collection of Cinnamon Spices extensions (optional via USE flags)"
HOMEPAGE="https://github.com/linuxmint/cinnamon-spices-extensions"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RDEPEND="gnome-extra/cinnamon"

# Supported Cinnamon extensions
IUSE="+screenshot +transparent-panels +tiling"

# Cinnamon 6.4 or newer is required
RDEPEND=">=gnome-extra/cinnamon-6.4"

# Use a pinned commit for reproducibility (recommended)
# Update this when upstream extensions are updated
COMMIT="2c0b1a6e3c7a9cf6c1e7d1b842c93a9a86f36458"
SRC_URI="https://github.com/linuxmint/cinnamon-spices-extensions/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/cinnamon-spices-extensions-${COMMIT}"

src_install() {
    if use screenshot; then
        einfo "Installing Cinnamon Screenshot extension..."
        local ext="cinnamon-screenshot@hilyxx"
        insinto /usr/share/cinnamon/extensions/${ext}
        doins -r "${S}/${ext}/files/${ext}"/* || die "Failed to install ${ext}"
        dodoc "${S}/${ext}/files/${ext}/README.md" 2>/dev/null || :
    fi

    if use transparent-panels; then
        einfo "Installing Cinnamon Transparent Panels extension..."
        local ext="transparent-panels@raresv"
        insinto /usr/share/cinnamon/extensions/${ext}
        doins -r "${S}/${ext}/files/${ext}"/* || die "Failed to install ${ext}"
        dodoc "${S}/${ext}/files/${ext}/README.md" 2>/dev/null || :
    fi

    if use tiling; then
        einfo "Installing Cinnamon Tiling extension..."
        local ext="tiling@odan"
        insinto /usr/share/cinnamon/extensions/${ext}
        doins -r "${S}/${ext}/files/${ext}"/* || die "Failed to install ${ext}"
        dodoc "${S}/${ext}/files/${ext}/README.md" 2>/dev/null || :
    fi
}