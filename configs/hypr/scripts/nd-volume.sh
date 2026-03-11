#!/usr/bin/env bash
# ---- NECRODERMIS — VOLUME CONTROL ----
# Called by swaync volume slider
# Usage: nd-volume.sh <0-100>

LEVEL="$1"

if [[ -z "$LEVEL" ]]; then
    # No arg — just print current volume for display
    pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1
    exit 0
fi

# Clamp to 0-100
if (( LEVEL < 0 )); then LEVEL=0; fi
if (( LEVEL > 100 )); then LEVEL=100; fi

pactl set-sink-volume @DEFAULT_SINK@ "${LEVEL}%"
