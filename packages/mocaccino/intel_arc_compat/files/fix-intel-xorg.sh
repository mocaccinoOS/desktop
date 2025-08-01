#!/bin/bash

XORG_CONF_DIR="/etc/X11/xorg.conf.d"
XORG_CONF_FILE="$XORG_CONF_DIR/20-intel.conf"
INTEL_DRIVER_PATH="/usr/lib64/xorg/modules/drivers/intel_drv.so"

# Ensure the directory exists
mkdir -p "$XORG_CONF_DIR"

# Detect Intel ARC Alchemist or Battlemage GPU using PCI ID
if lspci -nn | grep -i "VGA" | grep -E "Intel Corporation.*\[(8086:(56|e2)[0-9a-f]{2})\]"; then
    echo "Intel ARC Alchemist or Battlemage GPU detected."

    # Check if the legacy xf86-video-intel driver exists
    if [ -f "$INTEL_DRIVER_PATH" ]; then
        echo "Legacy Intel driver detected: $INTEL_DRIVER_PATH"

        # Enforce the use of the modesetting driver
        if [ ! -f "$XORG_CONF_FILE" ]; then
            echo "Creating $XORG_CONF_FILE to enforce modesetting."

            cat <<EOF > "$XORG_CONF_FILE"
Section "Device"
  Identifier "Intel Graphics"
  Driver "modesetting"
EndSection
EOF
        else
            echo "$XORG_CONF_FILE already exists. No changes made."
        fi
    else
        echo "No legacy Intel driver found. No changes needed."
    fi
else
    echo "No Intel ARC Alchemist or Battlemage GPU detected. No changes needed."
fi