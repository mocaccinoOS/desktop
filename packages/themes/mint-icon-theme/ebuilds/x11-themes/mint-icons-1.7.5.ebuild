# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Mint-X icon theme for Linux Mint (based on Faenza and Elementary)"
HOMEPAGE="https://github.com/linuxmint/mint-x-icons"

MY_PN="mint-x-icons"
MY_P="${MY_PN}_${PV}"
SRC_URI="http://packages.linuxmint.com/pool/main/m/${MY_PN}/${MY_P}.tar.xz"
S="${WORKDIR}/${MY_PN}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	x11-libs/gdk-pixbuf
	x11-misc/gtk-update-icon-cache
"

src_install() {
	find "${S}" -type d ! -perm 755 -exec chmod 755 {} +
	find "${S}" -type f ! -perm 644 -exec chmod 644 {} +

	insinto /usr/share/icons
	doins -r usr/share/icons/.
}

pkg_postinst() {
	local theme
	for theme in "${EROOT}"/usr/share/icons/Mint-X*; do
		[[ -d "${theme}" ]] && gtk-update-icon-cache -qf "${theme}"
	done
}

pkg_postrm() {
	local theme
	for theme in "${EROOT}"/usr/share/icons/Mint-X*; do
		[[ -d "${theme}" ]] && gtk-update-icon-cache -qf "${theme}"
	done
}