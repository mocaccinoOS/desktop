EAPI=8

inherit meson xdg-utils

DESCRIPTION="Xreader – Document viewer for PDF, Postscript, and more (X-Apps)"
HOMEPAGE="https://github.com/linuxmint/xreader"
SRC_URI="https://github.com/linuxmint/xreader/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-libs/glib:2
	x11-libs/gtk+:3
	x11-libs/xapp
	x11-libs/libX11
	media-libs/libexif
	app-text/poppler
"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/gettext
"

BDEPEND="dev-util/intltool"

S="${WORKDIR}/${P}"

src_configure() {
	meson setup build --prefix=/usr --buildtype=release
}

src_compile() {
	meson compile -C build
}

src_install() {
	DESTDIR="${D}" meson install -C build
	dodoc README.md NEWS
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
}
