#!/bin/bash

/usr/sbin/env-update
. /etc/profile

sd_enable() {
	local srv="${1}"
	local ext=".${2:-service}"
	[[ -x /bin/systemctl ]] && \
		systemctl --no-reload enable -f "${srv}${ext}"
}

sd_disable() {
	local srv="${1}"
	local ext=".${2:-service}"
	[[ -x /bin/systemctl ]] && \
		systemctl --no-reload disable -f "${srv}${ext}"
}


setup_displaymanager() {
	# determine what is the login manager
	if [ -n "$(equo match --installed gnome-base/gdm -qv)" ]; then
		sd_enable gdm
	elif [ -n "$(equo match --installed lxde-base/lxdm -qv)" ]; then
		sd_enable lxdm
	elif [ -n "$(equo match --installed x11-misc/lightdm-base -qv)" ]; then
		sd_enable lightdm
	elif [ -n "$(equo match --installed kde-base/kdm -qv)" ]; then
		sd_enable kdm
  elif [ -n "$(equo match --installed x11-misc/sddm -qv)" ]; then
    sd_enable sddm
	else
		sd_enable xdm
	fi
}

setup_fonts() {
	# Cause some rendering glitches on vbox as of 2011-10-02
	#	10-autohint.conf
	#	10-no-sub-pixel.conf
	#	10-sub-pixel-bgr.conf
	#	10-sub-pixel-rgb.conf
	#	10-sub-pixel-vbgr.conf
	#	10-sub-pixel-vrgb.conf
	#	10-unhinted.conf
	FONTCONFIG_ENABLE="
		20-unhint-small-dejavu-sans.conf
		20-unhint-small-dejavu-sans-mono.conf
		20-unhint-small-dejavu-serif.conf
		31-cantarell.conf
		52-infinality.conf
		57-dejavu-sans.conf
		57-dejavu-sans-mono.conf
		57-dejavu-serif.conf"
	for fc_en in ${FONTCONFIG_ENABLE}; do
		if [ -f "/etc/fonts/conf.avail/${fc_en}" ]; then
			# beautify font rendering
			eselect fontconfig enable "${fc_en}"
		else
			echo "ouch, /etc/fonts/conf.avail/${fc_en} is not available" >&2
		fi
	done
	# Complete infinality setup
	eselect infinality set infinality
	eselect lcdfilter set infinality
}

setup_default_xsession() {
	local sess="${1}"
	echo "[Desktop]" > /etc/skel/.dmrc
	echo "Session=${sess}" >> /etc/skel/.dmrc
	rm -vf /usr/share/xsessions/default.desktop || true
	ln -sf "${sess}.desktop" /usr/share/xsessions/default.desktop
}

setup_installed_packages() {
	# Update package list
	equo query list installed -qv > /etc/sabayon-pkglist
	echo -5 | equo conf update

	echo "Vacuum cleaning client db"
	rm /var/lib/entropy/client/database/*/sabayonlinux.org -rf
	rm /var/lib/entropy/client/database/*/sabayon-limbo -rf
	rm /var/lib/entropy/client/database/*/sabayon-weekly -rf
	equo rescue vacuum

	# cleanup log dir
	rm /var/lib/entropy/logs -rf
	rm -rf /var/lib/entropy/*cache*
	# remove entropy pid file
	rm -f /run/entropy/entropy.lock
	rm -f /var/lib/entropy/entropy.pid
	rm -f /var/lib/entropy/entropy.lock
}

setup_networkmanager() {
	sd_enable NetworkManager
	sd_enable ModemManager
}

prepare_gnome() {
	if [ -f "/usr/share/xsessions/cinnamon.desktop" ]; then
		setup_default_xsession "cinnamon"
	else
		setup_default_xsession "gnome"
	fi

	#setup_sabayon_mce
	#setup_sabayon_steambox
}

# Make sure that external Portage env vars are not set
unset PORTDIR PORTAGE_TMPDIR

# Activate services for systemd
SYSTEMD_SERVICES=(
	# Check if needed for gnome iso
	"avahi-daemon"
	"cups"
	"cups-browsed"
#	"sabayon-mce"
# "sabayon-steambox"
	"gdm"
)
for srv in "${SYSTEMD_SERVICES[@]}"; do
	sd_enable "${srv}"
done


eselect opengl set xorg-x11

systemctl --no-reload set-default graphical

prepare_gnome

setup_installed_packages
setup_networkmanager

ldconfig


# Create a default "games" group so that
# the default user will be added to it during
# live boot, and thus, after install.
# See bug 3134
groupadd -f games

setup_fonts

exit 0
