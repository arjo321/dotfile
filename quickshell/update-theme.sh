#!/bin/bash
# Regenerate the wallpaper palette for the quickshell bar.
# Usage: ./update-theme.sh /path/to/wallpaper.png
#
# matugen renders ~/.config/quickshell/templates/colors.json into
# ~/.cache/quickshell/colors.json; quickshell watches that file and
# recolors live, so no restart is needed.
WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
    echo "usage: $0 <wallpaper-image>" >&2
    exit 1
fi

# --prefer darkness: take the source color from the wallpaper's dark regions,
# so white/bright parts of an image never drive the palette.
matugen image "$WALLPAPER" --prefer darkness
