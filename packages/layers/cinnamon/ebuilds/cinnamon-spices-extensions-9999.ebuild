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

IUSE="+screenshot +transparent-panels +tiling blur-overview desktop-cube magic-lamp"

RDEPEND=">=gnome-extra/cinnamon-6.4"

src_install() {
    local ext_name ext_dir
    
    # Map USE flags to extension names
    local -A extensions=(
        [screenshot]="cinnamon-screenshot@hilyxx"
        [transparent-panels]="transparent-panels@germanfr"
        [tiling]="gTile@shuairan"
        [blur-overview]="blur-overview@nailfarmer.nailfarmer.com"
        [desktop-cube]="DesktopCube@yare"
        [magic-lamp]="CinnamonMagicLamp@klangman"
    )
    
    insinto /usr/share/cinnamon/extensions
    
    for flag in "${!extensions[@]}"; do
        if use ${flag}; then
            ext_name="${extensions[${flag}]}"
            ext_dir="${ext_name}/files/${ext_name}"
            
            if [[ -d "${ext_dir}" ]]; then
                einfo "Installing ${ext_name}"
                doins -r "${ext_dir}"
            else
                die "Extension directory not found: ${ext_dir}"
            fi
        fi
    done
    
    # Install documentation if present
    if [[ -f README.md ]]; then
        dodoc README.md
    fi
}

pkg_postinst() {
    elog "Cinnamon Spices extensions have been installed."
    elog "To enable them, open Cinnamon Settings > Extensions"
    elog ""
    elog "Installed extensions:"
    use screenshot && elog "  - Screenshot tool (cinnamon-screenshot@hilyxx)"
    use transparent-panels && elog "  - Transparent panels (transparent-panels@germanfr)"
    use tiling && elog "  - Window tiling (gTile@shuairan)"
    use blur-overview && elog "  - Blur overview (blur-overview@nailfarmer.nailfarmer.com)"
    use desktop-cube && elog "  - Desktop cube (DesktopCube@yare)"
    use magic-lamp && elog "  - Magic lamp effect (CinnamonMagicLamp@klangman)"
}