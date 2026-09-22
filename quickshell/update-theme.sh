#!/bin/bash
WALLPAPER="$1"

# 1. Run matugen to generate/apply colors or output json
matugen image "$WALLPAPER" -j hex > "$HOME/.config/quickshell/colors.json"

# Alternatively, if matugen generates template files directly for your shell, 
# you can trigger a quickshell reload:
qs -c quickshell &
