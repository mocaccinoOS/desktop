# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	anyhow@1.0.86
	chrono@0.4.38
	clap@4.5.15
	crossterm@0.29.0
	dirs@6.0.0
	include_dir@0.7.4
	libudev@0.3.0
	nom@8.0.0
	ratatui@0.30.0
	regex@1.11.0
	serde@1.0.208
	serde_json@1.0.125
	toml@0.9.0
	unicode-width@0.2.0
"

inherit cargo

DESCRIPTION="Fast Rust TUI for managing QEMU/KVM virtual machines"
HOMEPAGE="https://github.com/mroboff/vm-curator"
SRC_URI="
	https://github.com/mroboff/vm-curator/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	$(cargo_crate_uris ${CRATES})
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	virtual/libudev:=
"

RDEPEND="
	${DEPEND}
	app-emulation/qemu
"

BDEPEND="
	virtual/pkgconfig
	virtual/rust
"

src_install() {
	cargo_src_install
	dodoc README.md
}