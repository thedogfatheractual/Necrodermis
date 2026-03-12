#!/usr/bin/env bash
# Necrodermis — random wallpaper rotator
# Picks a random image from $wallDIR every 15 minutes

WALL_DIR="$HOME/Pictures/wallpapers/necrodermis"

while true; do
    WALL=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
    [[ -n "$WALL" ]] && swww img "$WALL" --transition-type fade --transition-duration 2
    sleep 900
done
