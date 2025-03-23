#!/bin/bash

if ! command -v flatpak &> /dev/null; then
    echo "Flatpak is not installed. Please install Flatpak first."
    exit 1  # Exit if Flatpak is not installed
fi

# Path to the system-wide flatpak repo config file
FLATPAK_CONFIG_DIR="/etc/flatpak/repositories.d"
FLATPAK_CONFIG_FILE="${FLATPAK_CONFIG_DIR}/flathub.conf"

# Ensure the repositories directory exists
if [ ! -d "$FLATPAK_CONFIG_DIR" ]; then
    echo "Creating directory $FLATPAK_CONFIG_DIR for Flatpak repository configurations..."
    sudo mkdir -p "$FLATPAK_CONFIG_DIR"
fi

# Check if flathub is already present in the config
if ! grep -q '\[remote "flathub"\]' "$FLATPAK_CONFIG_FILE"; then
    echo "Flathub repository not found, adding it..."

    # Append Flathub configuration to the file
    sudo tee -a "$FLATPAK_CONFIG_FILE" <<EOF
[remote "flathub"]
url=https://dl.flathub.org/repo/
xa.title=Flathub
gpg-verify=true
gpg-verify-summary=true
xa.comment=Central repository of Flatpak applications
xa.description=Central repository of Flatpak applications
xa.icon=https://dl.flathub.org/repo/logo.svg
xa.homepage=https://flathub.org/
EOF

    # Inform the user that the remote was added
    echo "Flathub repository added successfully."
else
    echo "Flathub repository is already enabled."
fi
