#!/usr/bin/env bash
# Necrodermis — scripts/functions/hypr.sh
# Component: install_hypr

install_hypr() {
    print_section "HYPRLAND  //  ENVIRONMENTAL CONTROL MATRIX"

    local HYPR_SRC="$SCRIPT_DIR/configs/hypr"
    local HYPR_DEST="$CONFIG_DIR/hypr"

    necro_print "hypr" "Deploying Hyprland configuration..."

    # ── Backup existing hypr config ───────────────────────────────────────────
    if [ -d "$HYPR_DEST" ] && [ ! -L "$HYPR_DEST" ]; then
        necro_backup "$HYPR_DEST"
    fi

    # ── Symlink entire hypr config directory ──────────────────────────────────
    if [ -L "$HYPR_DEST" ]; then
        rm "$HYPR_DEST"
    fi

    necro_run ln -sf "$HYPR_SRC" "$HYPR_DEST"

    necro_print "hypr" "Hyprland configuration linked — editing ~/.config/hypr edits the repo."
}
