#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/waybar.sh
# Component: install_waybar

install_waybar() {
    print_section "WAYBAR  //  STATUS ARRAY CALIBRATION"

    necro_pkg "waybar" waybar

    local WAYBAR_SRC="$SCRIPT_DIR/configs/waybar"
    local WAYBAR_DEST="$CONFIG_DIR/waybar"

    necro_print "waybar" "Deploying status array configuration..."

    if [ -d "$WAYBAR_DEST" ] && [ ! -L "$WAYBAR_DEST" ]; then
        necro_backup "$WAYBAR_DEST"
    fi

    if [ -L "$WAYBAR_DEST" ]; then
        rm "$WAYBAR_DEST"
    fi

    necro_run ln -sf "$WAYBAR_SRC" "$WAYBAR_DEST"

    necro_print "waybar" "Status array linked — editing ~/.config/waybar edits the repo."
}
