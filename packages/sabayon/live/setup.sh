#!/bin/bash

/usr/sbin/env-update
. /etc/profile

safe_run() {
	local updated=0
	for ((i=0; i < 42; i++)); do
		"${@}" && {
			updated=1;
			break;
		}
		if [ ${i} -gt 6 ]; then
			sleep 3600 || return 1
		else
			sleep 1200 || return 1
		fi
	done
	if [ "${updated}" = "0" ]; then
		return 1
	fi
	return 0
}

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

# Make sure that external Portage env vars are not set
unset PORTDIR PORTAGE_TMPDIR

# create /proc if it doesn't exist
# rsync doesn't copy it
mkdir -p /proc
# do not create /proc/.keep or older anaconda will raise an exception
# touch /proc/.keep
rm -f /proc/.keep
mkdir -p /dev/shm
touch /dev/shm/.keep
mkdir -p /dev/pts
touch /dev/pts/.keep

# copy /root defaults from /etc/skel
rm -rf /root
cp /etc/skel /root -Rap
chown root:root /root -R

# Setup locale to en_US
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo LANGUAGE=en_US.UTF-8 >> /etc/locale.conf
echo LC_ALL=en_US.UTF-8 >> /etc/locale.conf
# Make sure that 02locale is a symlink to locale.conf
rm -f /etc/env.d/02locale
ln -sf ../locale.conf /etc/env.d/02locale


# Cleanup Perl cruft
perl-cleaner --ph-clean

# Needed by systemd, because it doesn't properly set a good
# encoding in ttys. Test it with (on tty1, VT1):
# echo -e "\xE2\x98\xA0"
# TODO: check if the issue persists with systemd 202.
echo FONT=LatArCyrHeb-16 > /etc/vconsole.conf

# since this comes without X, set the default target to multi-user.target
# instead of graphical.target
systemctl --no-reload set-default multi-user

# remove SSH keys
rm -rf /etc/ssh/*_key*

# remove LDAP keys
rm -f /etc/openldap/ssl/ldap.pem /etc/openldap/ssl/ldap.key \
	/etc/openldap/ssl/ldap.csr /etc/openldap/ssl/ldap.crt

# better remove postfix package manager generated
# SSL certificates
rm -rf /etc/ssl/postfix/server.*

# make sure postfix only listens on localhost
echo "inet_interfaces = localhost" >> /etc/postfix/main.cf
# allow root logins to the livecd by default
# turn bashlogin shells to actual login shells
sed -i 's:exec -l /bin/bash:exec -l /bin/bash -l:' /bin/bashlogin

# setup /etc/hosts, add sabayon as default hostname (required by Xfce)
sed -i "/^127.0.0.1/ s/localhost/localhost sabayon/" /etc/hosts
sed -i "/^::1/ s/localhost/localhost sabayon/" /etc/hosts

# setup postfix local mail aliases
newaliases

echo "PLYMOUTH THEME LIST:"
plymouth-set-default-theme --list
# Set Plymouth default theme, newer artwork has the sabayon theme
is_ply_sabayon=$(plymouth-set-default-theme --list | grep sabayon)
if [ -n "${is_ply_sabayon}" ]; then
	plymouth-set-default-theme sabayon
else
	plymouth-set-default-theme solar
fi

# disable cd eject on shutdown/reboot, it's broken atm
sd_disable cdeject

# Activate services for systemd
SYSTEMD_SERVICES=(
	"NetworkManager"
	"sabayonlive"
	"bluetooth"
	"installer-text"
	"installer-gui"
)
for srv in "${SYSTEMD_SERVICES[@]}"; do
	sd_enable "${srv}"
done
# Disable syslog in systemd, we use journald
sd_disable syslog-ng

# Disable Dynamy linker cache rebuilding
sd_disable ldconfig.service

# Make sure to have lvmetad otherwise anaconda freaks out
sd_enable lvm2-lvmetad

# setup sudoers
[ -e /etc/sudoers ] && sed -i '/NOPASSWD: ALL/ s/^# //' /etc/sudoers

# setup opengl in /etc (if configured)
eselect opengl set xorg-x11 &> /dev/null

# touch /etc/asound.state
touch /etc/asound.state

type -f update-pciids 2> /dev/null && update-pciids
type -f update-usbids 2> /dev/null && update-usbids

echo -5 | etc-update
mount -t proc proc /proc


ldconfig
ldconfig
umount /proc

emaint --fix world

# copy Portage config from sabayonlinux.org entropy repo to system
for conf in package.mask package.unmask package.keywords make.conf package.use; do
	repo_path=/var/lib/entropy/client/database/*/sabayonlinux.org/standard
	repo_conf=$(ls -1 ${repo_path}/*/*/${conf} | sort | tail -n 1 2>/dev/null)
	if [ -n "${repo_conf}" ]; then
		target_path="/etc/portage/${conf}"
		if [ ! -d "${target_path}" ]; then # do not touch dirs
			cp "${repo_conf}" "${target_path}" # ignore
		fi
	fi
done
# split config files
for conf in 00-sabayon.package.use 00-sabayon.package.mask \
	00-sabayon.package.unmask 00-sabayon.package.keywords; do
	repo_path=/var/lib/entropy/client/database/*/sabayonlinux.org/standard
	repo_conf=$(ls -1 ${repo_path}/*/*/${conf} | sort | tail -n 1 2>/dev/null)
	if [ -n "${repo_conf}" ]; then
		target_path="/etc/portage/${conf/00-sabayon.}/${conf}"
		target_dir=$(dirname "${target_path}")
		if [ -f "${target_dir}" ]; then # remove old file
			rm "${target_dir}" # ignore failure
		fi
		if [ ! -d "${target_path}" ]; then
			mkdir -p "${target_path}" # ignore failure
		fi
		cp "${repo_conf}" "${target_path}" # ignore

	fi
done

### XXX: The base layer doesn't ship shadow files etc.
### We run in the finalizer this step so it gets applied in runtime only if no users/groups are setted up in the machine
if [ ! -e "/etc/shadow" ]; then
	cp -rfv /etc/shadow.defaults /etc/shadow
fi

if [ ! -e "/etc/gshadow" ]; then
	cp -rfv /etc/gshadow.defaults /etc/gshadow
fi
if [ ! -e "/etc/passwd" ]; then
	cp -rfv /etc/passwd.defaults /etc/passwd
fi
if [ ! -e "/etc/group" ]; then
	cp -rfv /etc/group.defaults /etc/group
fi

# Reset users' password
# chpasswd doesn't work anymore
root_zeropass="root::$(cat /etc/shadow | grep "root:" | cut -d":" -f3-)"
sed -i "s/^root:.*/${root_zeropass}/" /etc/shadow

# protect /var/tmp
touch /var/tmp/.keep
touch /tmp/.keep
chmod 777 /var/tmp
chmod 777 /tmp

# Be sure polkit and dbus bits are there (e.g. in case of separated dbus installs)
chown -R polkitd:polkitd /var/lib/polkit-1
chown -R polkitd:polkitd /etc/polkit-1/rules.d
chown root:messagebus /usr/libexec/dbus-daemon-launch-helper
chmod +s /usr/libexec/dbus-daemon-launch-helper

# TODO: Move to its own package when we have the spec
sed -i 's|/dev/live-base|/tmp/mnt/device/rootfs.squashfs|g' /etc/calamares/modules/unpackfs.conf
cp -rfv /patches/calamares.py /usr/lib64/calamares/modules/sabayon/main.py

# Looks like screen directories are missing
if [ ! -d "/run/screen" ]; then
	mkdir /run/screen
	chmod 775 /run/screen
	chown root:utmp /run/screen
fi

# Regenerate Fluxbox menu
if [ -x "/usr/bin/fluxbox-generate_menu" ]; then
	mkdir -p /root/.fluxbox
        fluxbox-generate_menu -o /etc/skel/.fluxbox/menu
fi

rm -rf /var/tmp/entropy/*
rm -rf /var/lib/entropy/logs
rm -rf /var/lib/entropy/glsa
rm -rf /var/lib/entropy/tmp
rm -rf /var/lib/entropy/*cache*

# Clean layman dir
rm -rf /var/lib/layman/* /etc/portage/repos.conf/layman.conf
# Needed
touch /var/lib/layman/make.conf

# remove entropy hwhash
rm -f /etc/entropy/.hw.hash

# remove entropy pid file
rm -f /run/entropy/entropy.lock
rm -f /var/lib/entropy/entropy.pid
rm -f /var/lib/entropy/entropy.lock # old?

# remove /run/* and /var/lock/*
# systemd mounts them using tmpfs
#rm -rf /run/*
#rm -rf /var/lock/*
exit 0