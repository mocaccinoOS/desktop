#!/bin/sh
# symlinks for start menu
for theme in breeze breeze-dark; do
  for size in 16 22 24; do
    dir="/usr/share/icons/${theme}/places/${size}"
    install -d "$dir"
    ln -sf /usr/share/icons/mOS-icons/scalable/apps/start-here-symbolic.svg \
      "${dir}/start-here-symbolic.svg"
  done
done

# TODO: wallpaper is still handled through a file in skel 
