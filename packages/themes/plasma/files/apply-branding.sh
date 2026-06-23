#!/bin/sh

# Install Look and Feel packages (Light and Dark)
for theme in org.mocaccino.desktop org.mocaccino.desktop.dark; do
  install -Dm644 files/lookandfeel/${theme}/metadata.json \
    /usr/share/plasma/look-and-feel/${theme}/metadata.json
  install -Dm644 files/lookandfeel/${theme}/contents/defaults \
    /usr/share/plasma/look-and-feel/${theme}/contents/defaults
  if [ -f files/lookandfeel/${theme}/contents/previews/preview.png ]; then
    install -Dm644 files/lookandfeel/${theme}/contents/previews/preview.png \
      /usr/share/plasma/look-and-feel/${theme}/contents/previews/preview.png
  fi
  if [ -f files/lookandfeel/${theme}/contents/previews/fullscreenpreview.jpg ]; then
    install -Dm644 files/lookandfeel/${theme}/contents/previews/fullscreenpreview.jpg \
      /usr/share/plasma/look-and-feel/${theme}/contents/previews/fullscreenpreview.jpg
  fi
done

# Create inherited icon themes for MocaccinoOS branding
for suffix in "" "-dark"; do
  theme="mocaccino-breeze${suffix}"
  parent="breeze${suffix}"
  name="Mocaccino Breeze"
  [ "$suffix" = "-dark" ] && name="Mocaccino Breeze Dark"

  # Base directory
  base_dir="/usr/share/icons/${theme}"
  install -d "${base_dir}"

  # Write index.theme
  cat <<EOF > "${base_dir}/index.theme"
[Icon Theme]
Name=${name}
Comment=${name} Icon Theme
Inherits=${parent},breeze,hicolor
DisplayDepth=32
LinkOverlay=overlay_link
ZipFormat=7z

# Directory list
Directories=places/16,places/22,places/24,places/scalable

[places/16]
Size=16
Context=Places
Type=Fixed

[places/22]
Size=22
Context=Places
Type=Fixed

[places/24]
Size=24
Context=Places
Type=Fixed

[places/scalable]
Size=256
MinSize=8
MaxSize=512
Context=Places
Type=Scalable
EOF

  # Select icon based on light/dark variant
  if [ "$suffix" = "-dark" ]; then
    icon="/usr/share/icons/mOS-icons/mOS_outlined_hl_w.png"
  else
    icon="/usr/share/icons/mOS-icons/mOS_outlined_hl.png"
  fi

  # Install the custom start menu icons as symlinks to system icons
  for size in 16 22 24; do
    dir="${base_dir}/places/${size}"
    install -d "$dir"
    ln -sf "${icon}" "${dir}/start-here-symbolic.svg"
    ln -sf "${icon}" "${dir}/start-here-kde-symbolic.svg"
  done

  # Scalable icons
  dir="${base_dir}/places/scalable"
  install -d "$dir"
  ln -sf "${icon}" "${dir}/start-here-symbolic.svg"
  ln -sf "${icon}" "${dir}/start-here-kde-symbolic.svg"
  ln -sf "${icon}" "${dir}/start-here-kde.svg"
done

# Apply MocaccinoOS theme as system-wide default
install -Dm644 files/kdeglobals /etc/xdg/kdeglobals


