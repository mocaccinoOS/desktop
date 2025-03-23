#!/bin/bash

if ! command -v flatpak &> /dev/null; then
    echo "Flatpak is not installed. Please install Flatpak first."
    exit 1  # Exit if Flatpak is not installed
fi

# Wait until flatpak is fully initialized
echo "Waiting for Flatpak to initialize..."
until flatpak --version &>/dev/null; do
    sleep 1
done

# Path to the system-wide flatpak repo config file
FLATPAK_CONFIG_DIR="/etc/flatpak/repositories.d"
FLATPAK_CONFIG_FILE="${FLATPAK_CONFIG_DIR}/flathub.conf"

# Ensure the repositories directory exists
if [ ! -d "$FLATPAK_CONFIG_DIR" ]; then
    echo "Creating directory $FLATPAK_CONFIG_DIR for Flatpak repository configurations..."
    mkdir -p "$FLATPAK_CONFIG_DIR"
fi

# Check if flathub is already present in the config
if ! grep -q '\[remote "flathub"\]' "$FLATPAK_CONFIG_FILE"; then
    echo "Flathub repository not found, adding it..."

    # Append the entire Flathub configuration in one echo statement
    cat <<EOF >> "$FLATPAK_CONFIG_FILE"
[remote "flathub"]
url=https://dl.flathub.org/repo/
gpg-verify=true
gpg-verify-summary=true
xa.title=Flathub
xa.comment=Central repository of Flatpak applications
xa.description=Central repository of Flatpak applications
xa.icon=https://dl.flathub.org/repo/logo.svg
xa.homepage=https://flathub.org/
EOF

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Inform the user that the remote was added
    echo "Flathub repository added successfully."
else
    echo "Flathub repository is already enabled."
fi
