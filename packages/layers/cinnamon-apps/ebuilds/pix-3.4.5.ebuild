EAPI=8

inherit meson

DESCRIPTION="Pix – image viewer, browser & organiser (X‑Apps)"
HOMEPAGE="https://github.com/linuxmint/pix"
SRC_URI="https://github.com/linuxmint/pix/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="exiv2 heif jxl raw svg webp"

RDEPEND="
	dev-libs/glib
	x11-libs/gtk+:3
	x11-libs/xapp
	media-libs/gstreamer
	media-libs/gst-plugins-base
	media-libs/libpng
	media-libs/libjpeg-turbo
	media-libs/tiff
	exiv2? ( media-libs/exiv2 )
	webp? ( media-libs/libwebp )
	jxl? ( media-libs/libjxl )
	heif? ( media-libs/libheif )
	raw? ( media-libs/libraw )
	svg? ( gnome-base/librsvg )
"

DEPEND="${RDEPEND}"

BDEPEND="
	virtual/pkgconfig
	sys-devel/gettext
"

S="${WORKDIR}/pix-${PV}"

src_configure() {
    meson setup build \
        -Dheif=$(usex heif) \
        -Djxl=$(usex jxl) \
        -Draw=$(usex raw) \
        -Dsvg=$(usex svg) \
        -Dwebp=$(usex webp) \
        -Dexiv2=$(usex exiv2) \
        --prefix="${EPREFIX}/usr"
}

src_compile() {
    meson compile -C build
}

src_install() {
    meson install -C build --destdir="${D}"
    dodoc README.md NEWS
}
