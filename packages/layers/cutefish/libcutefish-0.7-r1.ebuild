# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

if [[ ${PV} == 9999* ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/cutefishos/libcutefish.git"
	EGIT_CHECKOUT_DIR=${PN}-${PV}
	KEYWORDS=""
else
	EGIT_COMMIT="6bf2df8e91bcc21b116fec7df35d30d415122b39"
	SRC_URI="https://github.com/cutefishos/libcutefish/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm64 ~riscv ~loong"
	S="${WORKDIR}/${PN}-${EGIT_COMMIT}"
fi

DESCRIPTION="System library for Cutefish applications"
HOMEPAGE="https://github.com/cutefishos/libcutefish"
LICENSE="GPL-3"
SLOT="0"
IUSE=""
RDEPEND=""
DEPEND="
	dev-qt/qtcore
	dev-qt/qtgui
	dev-qt/qtdeclarative
	dev-qt/qtquickcontrols2
	dev-qt/qtdbus
	dev-qt/qtxml
	dev-qt/qtconcurrent
	kde-frameworks/bluez-qt
	kde-frameworks/networkmanager-qt
	kde-frameworks/modemmanager-qt
	kde-plasma/libkscreen
	kde-frameworks/kio
	dev-qt/qtsensors
	media-libs/libcanberra[pulseaudio]
"
BDEPEND="${DEPEND}
	dev-util/ninja
"
src_prepare(){
	sed -e 's|CMAKE_CXX_STANDARD 14|CMAKE_CXX_STANDARD 17|' -i libcutefish-0.7/CMakeLists.txt
}

src_configure(){
	mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="/usr"
	)
	cmake_src_configure
}
