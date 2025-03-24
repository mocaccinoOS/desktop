#!/bin/bash

if ! command -v flatpak &> /dev/null; then
    echo "Flatpak is not installed. Please install Flatpak first."
    exit 1  # Exit if Flatpak is not installed
fi

# Wait until Flatpak is fully initialized
echo "Waiting for Flatpak to initialize..."
until flatpak --version &>/dev/null; do
    sleep 1
done

# Path to the system-wide flatpak repo config file
FLATPAK_CONFIG_FILE="/var/lib/flatpak/repo/config"

# Check if Flathub is already in the config file
if ! grep -q '\[remote "flathub"\]' "$FLATPAK_CONFIG_FILE" 2>/dev/null; then
    echo "Flathub repository not found in the config, adding it..."

    # Add Flathub remote if not found in config
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo "Flathub repository added successfully."
else
    echo "Flathub repository is already in the config."
fi
