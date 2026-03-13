#!/usr/bin/env bash
# NECRODERMIS — scripts/necro-hyprlock-scale.sh
# Detects monitor resolution and writes the correct hyprlock config variant

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

necro_hyprlock_scale() {
    local target_conf=""

    # Pull primary monitor resolution via hyprctl if available
    if command -v hyprctl &>/dev/null; then
        local res
        res=$(hyprctl monitors -j 2>/dev/null \
            | python3 -c "
import json,sys
mons = json.load(sys.stdin)
if mons:
    m = next((x for x in mons if x.get('focused')), mons[0])
    print(str(m['width']) + 'x' + str(m['height']))
" 2>/dev/null)

        case "$res" in
            1920x1080|1920x1200) target_conf="hyprlock-1080p.conf" ;;
            2560x1440|2560x1600) target_conf="hyprlock-2k.conf"   ;;
            3840x2160)           target_conf="hyprlock-2k.conf"   ;;
            *)                   target_conf="hyprlock-1080p.conf" ;;
        esac
    else
        # fallback — no hyprctl
        target_conf="hyprlock-1080p.conf"
    fi

    local src="$HYPR_CONFIG_DIR/$target_conf"
    local dst="$HYPR_CONFIG_DIR/hyprlock.conf"

    if [[ ! -f "$src" ]]; then
        echo "[necro-scale] source not found: $src — skipping" >&2
        return 1
    fi

    cp "$src" "$dst"
    echo "[necro-scale] hyprlock scaled to $target_conf"
}

necro_hyprlock_scale
