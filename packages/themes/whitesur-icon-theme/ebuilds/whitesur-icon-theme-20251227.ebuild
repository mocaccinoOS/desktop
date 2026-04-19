# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="MacOS Big Sur style icon theme for Linux desktops"
HOMEPAGE="https://github.com/vinceliuice/WhiteSur-icon-theme"

MY_TAG="2025-12-27"
SRC_URI="https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/tags/${MY_TAG}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/WhiteSur-icon-theme-${MY_TAG}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="alternative bold kde +purple +pink +red +orange +yellow +green +grey +nord"

RDEPEND="dev-util/gtk-update-icon-cache"

# Translate USE flags to theme suffix strings
_theme_variants() {
	local themes=( '' )  # default (blue) is always included
	use purple && themes+=( '-purple' )
	use pink   && themes+=( '-pink' )
	use red    && themes+=( '-red' )
	use orange && themes+=( '-orange' )
	use yellow && themes+=( '-yellow' )
	use green  && themes+=( '-green' )
	use grey   && themes+=( '-grey' )
	use nord   && themes+=( '-nord' )
	echo "${themes[@]}"
}

# Install one (theme, color) variant.
# $1 = theme suffix e.g. '' or '-purple'
# $2 = color suffix: '' | '-light' | '-dark'
_install_variant() {
	local theme=${1} color=${2}
	local name=WhiteSur
	local dest="${ED}/usr/share/icons"
	local THEME_DIR="${dest}/${name}${theme}${color}"
	local BASE_DIR="${dest}/${name}${theme}"  # used for symlinks from light/dark

	mkdir -p "${THEME_DIR}" || die

	# --- index.theme ---
	cp "${S}/src/index.theme" "${THEME_DIR}/index.theme" || die
	sed -i "s/WhiteSur/${name}${theme}${color}/g" \
		"${THEME_DIR}/index.theme" || die

	if [[ -z "${color}" ]]; then
		# -------------------------------------------------------
		# Standard variant
		# -------------------------------------------------------
		mkdir -p "${THEME_DIR}/status" || die

		cp -r "${S}"/src/{actions,animations,apps,categories,devices,emotes,emblems,mimes,places,preferences} \
			"${THEME_DIR}/" || die
		cp -r "${S}"/src/status/{16,22,24,32,symbolic} \
			"${THEME_DIR}/status/" || die

		# bold panel icons (replaces 16/22/24 status sizes)
		if use bold; then
			cp -r "${S}"/bold/status/{16,22,24} \
				"${THEME_DIR}/status/" || die
		fi

		# alternative app/file-manager icons
		if use alternative; then
			cp -r "${S}"/alternative/. "${THEME_DIR}/" || die
		fi

		# kde plasma logo replaces apple logo
		if use kde; then
			cp -r "${S}"/plasma/. "${THEME_DIR}/" || die
		fi

		# coloured folder icons
		if [[ -n "${theme}" ]]; then
			cp -r "${S}"/colors/color${theme}/*.svg \
				"${THEME_DIR}/places/scalable/" || die
		fi

		# symbolic links for icon name aliases
		cp -r "${S}"/links/{actions,apps,categories,devices,emotes,emblems,mimes,places,preferences} \
			"${THEME_DIR}/" || die
		mkdir -p "${THEME_DIR}/status" || die
		cp -r "${S}"/links/status/{16,22,24,32,symbolic} \
			"${THEME_DIR}/status/" || die

		# remove dark-only trash icons from standard variant
		rm -f "${THEME_DIR}"/status/16/trash-full-dark.svg \
			"${THEME_DIR}"/status/16/trash-empty-dark.svg || die

	elif [[ "${color}" == '-light' ]]; then
		# -------------------------------------------------------
		# Light variant — only status icons, recoloured;
		# everything else symlinks back to the base theme dir.
		# -------------------------------------------------------
		mkdir -p "${THEME_DIR}/status" || die

		cp -r "${S}"/src/status/{16,22,24,32,symbolic} \
			"${THEME_DIR}/status/" || die

		# recolour: white (#f2f2f2) → near-black (#363636)
		find "${THEME_DIR}/status" -name '*.svg' -exec \
			sed -i 's/#f2f2f2/#363636/g' {} + || die

		cp -r "${S}"/links/status/{16,22,24,32,symbolic} \
			"${THEME_DIR}/status/" || die

		# symlink all non-status categories to the base theme
		local cat
		for cat in actions animations apps categories devices emotes \
		           emblems mimes places preferences; do
			ln -sr "${BASE_DIR}/${cat}" "${THEME_DIR}/${cat}" || die
		done

	elif [[ "${color}" == '-dark' ]]; then
		# -------------------------------------------------------
		# Dark variant — only status icons, recoloured;
		# everything else symlinks back to the base theme dir.
		# -------------------------------------------------------
		mkdir -p "${THEME_DIR}/status" || die

		cp -r "${S}"/src/status/{16,22,24,32} \
			"${THEME_DIR}/status/" || die

		# recolour: near-black (#363636) → light grey (#dedede)
		find "${THEME_DIR}/status" -name '*.svg' -exec \
			sed -i 's/#363636/#dedede/g' {} + || die

		# rename dark-variant trash icons into place
		local size
		for size in 16; do
			if [[ -f "${THEME_DIR}/status/${size}/trash-full-dark.svg" ]]; then
				mv "${THEME_DIR}/status/${size}/trash-full-dark.svg" \
					"${THEME_DIR}/status/${size}/trash-full.svg" || die
			fi
			if [[ -f "${THEME_DIR}/status/${size}/trash-empty-dark.svg" ]]; then
				mv "${THEME_DIR}/status/${size}/trash-empty-dark.svg" \
					"${THEME_DIR}/status/${size}/trash-empty.svg" || die
			fi
		done

		cp -r "${S}"/links/status/{16,22,24,32} \
			"${THEME_DIR}/status/" || die

		# symlink all non-status categories to the base theme
		local cat
		for cat in actions animations apps categories devices emotes \
		           emblems mimes places preferences; do
			ln -sr "${BASE_DIR}/${cat}" "${THEME_DIR}/${cat}" || die
		done
	fi

	# HiDPI @2x symlinks for every installed directory
	local dir
	for dir in "${THEME_DIR}"/*/; do
		[[ -d "${dir}" ]] || continue
		local dname="${dir%/}"
		dname="${dname##*/}"
		ln -sr "${THEME_DIR}/${dname}" "${THEME_DIR}/${dname}@2x" || die
	done
}

src_install() {
	local theme
	for theme in $(_theme_variants); do
		local color
		for color in '' '-light' '-dark'; do
			_install_variant "${theme}" "${color}"
		done
	done

	dodoc AUTHORS README.md
}

pkg_postinst() {
	local theme
	for theme in "${EROOT}"/usr/share/icons/WhiteSur*/; do
		[[ -d "${theme}" ]] && gtk-update-icon-cache -qf "${theme}"
	done
}

pkg_postrm() {
	local theme
	for theme in "${EROOT}"/usr/share/icons/WhiteSur*/; do
		[[ -d "${theme}" ]] && gtk-update-icon-cache -qf "${theme}"
	done
}