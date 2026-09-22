#!/usr/bin/env bash

WALL_DIR="$HOME/Pictures/Wallpapers"

# 1. Select the wallpaper via Rofi
SELECTED=$(for pic in "$WALL_DIR"/*; do
    filename=$(basename "$pic")
    echo -en "$filename\0icon\x1f$pic\n"
done | rofi -dmenu -show-icons -i -p "󰸉 Pick Wallpaper" -theme ~/.config/rofi/wallpaper-picker.rasi)

if [ -z "$SELECTED" ]; then
    exit 0
fi

WALLPAPER="$WALL_DIR/$SELECTED"

# 2. Check if awww is running, start it if it isn't
if ! awww query &> /dev/null; then
    awww-daemon &
    sleep 1 # Give the daemon a second to boot up
fi

# 3. Apply wallpaper using the new awww command
awww img "$WALLPAPER" --transition-type wipe --transition-duration 1.5

# 4. Generate colors (Bypassing the interactive prompt)
matugen image "$WALLPAPER" --source-color-index 0
