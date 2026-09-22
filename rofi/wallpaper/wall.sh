#!/bin/bash

dir="$HOME/.config/rofi/wallpaper"
theme='style-1'
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/wall_thumb"

mkdir -p $CACHE_DIR

for f in $(ls -v "$WALLPAPER_DIR"/*.png); do
    num=$(basename "$f" .png)
    thumb="$CACHE_DIR/$num.png"
    if [ ! -f "$thumb" ]; then
      convert "$f" -thumbnail 200x120 "$thumb"
    fi
done

CHOICE=$(
  for f in $(ls -v "$WALLPAPER_DIR"/*.png); do
    num=$(basename "$f" .png)
    printf " \x00icon\x1f%s\n" "$CACHE_DIR/$num.png"
  done | rofi -dmenu \
    -p "󰸉 " \
    -theme ${dir}/${theme}.rasi \
    -show-icons \
    -i \
    -theme-str 'element-icon { size: 130px; }' \
    -format i
)

if [ -n "$CHOICE" ]; then
  files=($(ls -v "$WALLPAPER_DIR"/*.png))
  CHOSEN_FILE="${files[$CHOICE]}"
  
  # 1. Update the lockscreen background
  ln -f "$CHOSEN_FILE" "$HOME/.config/hypr/hyprlock/wallpaper"

  # 2. Change the actual desktop background (change swww to awww if needed)
  swww img "$CHOSEN_FILE" --transition-type grow

  # 3. Extract the tactical dark colors
  matugen image "$CHOSEN_FILE" -m dark --source-color-index 2

  # 4. Kill and restart Waybar securely in the background
  pkill waybar
  sleep 0.2
  waybar > /dev/null 2>&1 &
fi