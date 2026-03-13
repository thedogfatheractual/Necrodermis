#!/usr/bin/env bash
# NECRODERMIS — touchpad-toggle.sh
# Toggles touchpad enabled/disabled via hyprctl

DEVICE=$(hyprctl devices -j | python3 -c "
import sys, json
devices = json.load(sys.stdin)
for d in devices.get('mice', []):
    if 'touchpad' in d.get('name', '').lower():
        print(d['name'])
        break
" 2>/dev/null)

if [[ -z "$DEVICE" ]]; then
    notify-send "Necrodermis" "No touchpad detected" --urgency=low
    exit 1
fi

ENABLED=$(hyprctl getoption "input:touchpad:enabled" | grep -oP '(?<=int: )\d')

if [[ "$ENABLED" == "1" ]]; then
    hyprctl keyword input:touchpad:enabled 0
    notify-send "Necrodermis" "Touchpad disabled" --urgency=low
else
    hyprctl keyword input:touchpad:enabled 1
    notify-send "Necrodermis" "Touchpad enabled" --urgency=low
fi
