EAPI=8

inherit meson

DESCRIPTION="Xreader – multi-page document viewer (X‑Apps)"
HOMEPAGE="https://github.com/linuxmint/xreader"
SRC_URI="https://github.com/linuxmint/xreader/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="djvu dvi ps xps rar cbz webp"

RDEPEND="
	dev-libs/glib
	x11-libs/gtk+:3
	x11-libs/xapp
	app-text/poppler
	djvu? ( media-libs/djvulibre )
	xps? ( dev-libs/libgxps )
	ps? ( app-text/ghostscript-gpl )
	cbz? ( app-arch/unzip )
	rar? ( app-arch/unrar )
	webp? ( media-libs/libwebp )
"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/gettext
"

S="${WORKDIR}/xreader-${PV}"

src_configure() {
    meson setup build \
        -Ddjvu=$(usex djvu) \
        -Dxps=$(usex xps) \
        -Dps=$(usex ps) \
        -Dcbz=$(usex cbz) \
        -Drar=$(usex rar) \
        -Dwebp=$(usex webp) \
        --prefix="${EPREFIX}/usr"
}

src_compile() {
    meson compile -C build
}

src_install() {
    meson install -C build --destdir="${D}"
    dodoc README.md NEWS
}
