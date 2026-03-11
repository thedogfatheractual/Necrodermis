#!/usr/bin/env bash
# Necrodermis — scripts/functions/wlogout.sh
# Component: install_wlogout

install_wlogout() {
    print_section "WLOGOUT  //  TOMB SEAL INTERFACE"

    local WLOGOUT_SRC="$SCRIPT_DIR/configs/wlogout"
    local WLOGOUT_DEST="$CONFIG_DIR/wlogout"

    necro_print "wlogout" "Deploying tomb seal configuration..."

    if [ -d "$WLOGOUT_DEST" ] && [ ! -L "$WLOGOUT_DEST" ]; then
        necro_backup "$WLOGOUT_DEST"
    fi

    if [ -L "$WLOGOUT_DEST" ]; then
        rm "$WLOGOUT_DEST"
    fi

    necro_run ln -sf "$WLOGOUT_SRC" "$WLOGOUT_DEST"

    necro_print "wlogout" "Tomb seal linked — editing ~/.config/wlogout edits the repo."
}
