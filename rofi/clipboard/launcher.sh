#!/usr/bin/env bash

dir="$HOME/.config/rofi/clipboard"
theme="style-1"

cliphist list \
    | rofi -dmenu -p " " -theme "${dir}/${theme}.rasi" \
    | cliphist decode \
    | wl-copy