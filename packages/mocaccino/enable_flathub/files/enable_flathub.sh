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
FLATPAK_CONFIG_FILE="${FLATPAK_CONFIG_DIR}/flathub.flatpakrepo"

# Ensure the repositories directory exists
if [ ! -d "$FLATPAK_CONFIG_DIR" ]; then
    echo "Creating directory $FLATPAK_CONFIG_DIR for Flatpak repository configurations..."
    mkdir -p "$FLATPAK_CONFIG_DIR"
fi

# Check if the Flathub URL is already in the config file
if ! grep -q 'https://dl.flathub.org/repo/' "$FLATPAK_CONFIG_FILE" 2>/dev/null; then
    echo "Flathub repository not found, adding it..."

    # Download the Flathub flatpakrepo file using wget
    wget -q -O "$FLATPAK_CONFIG_FILE" https://dl.flathub.org/repo/flathub.flatpakrepo

    # Inform the user that the remote was added
    echo "Flathub repository added successfully."
else
    echo "Flathub repository is already enabled."
fi
