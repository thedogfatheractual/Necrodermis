#!/usr/bin/env bash
# /* ---- SAUTEKH DYNASTY — NECRON BORDER PROTOCOL ---- */
# Two-color gradient flow: neon Necron green glow crawling over deep void green
# Slow, deliberate — like a Necron waking from stasis

# Kill any previous instance of this script to avoid stacking
[[ -n "$FLOCKER" ]] || exec env FLOCKER="$$" flock -en "$0" "$0" "$@" || exit 0

# ---------- SAUTEKH TWO-COLOR PALETTE ----------
NEON="0xff00ff00"    # Necron green — gauss glow peak
MID="0xff00cc00"     # mid green — glow shoulder
DEEP="0xff006600"    # deep green — base field
VOID="0xff003300"    # void green — darkest point

# Gradient positions — 10 slots cycling the glow point
COLORS=(
    "$VOID"
    "$VOID"
    "$DEEP"
    "$DEEP"
    "$MID"
    "$NEON"
    "$MID"
    "$DEEP"
    "$DEEP"
    "$VOID"
)

OFFSET=0
SLEEP_INTERVAL=1.2   # seconds between steps — adjust for faster/slower

while true; do
    # Build color list rotated by current offset
    COLOR_ARGS=()
    for i in {0..9}; do
        idx=$(( (i + OFFSET) % 10 ))
        COLOR_ARGS+=("${COLORS[$idx]}")
    done

    hyprctl keyword general:col.active_border \
        "${COLOR_ARGS[@]}" 270deg 2>/dev/null

    OFFSET=$(( (OFFSET + 1) % 10 ))
    sleep "$SLEEP_INTERVAL"
done
