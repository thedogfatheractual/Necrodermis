#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/swaync.sh
# Component: install_swaync

install_swaync() {
    print_section "SWAYNC  //  NOTIFICATION RELAY NODE"

    necro_yay "swaync" swaync

    local SWAYNC_SRC="$SCRIPT_DIR/configs/swaync"
    local SWAYNC_DEST="$CONFIG_DIR/swaync"

    necro_print "swaync" "Deploying notification relay configuration..."

    if [ -d "$SWAYNC_DEST" ] && [ ! -L "$SWAYNC_DEST" ]; then
        necro_backup "$SWAYNC_DEST"
    fi

    if [ -L "$SWAYNC_DEST" ]; then
        rm "$SWAYNC_DEST"
    fi

    necro_run ln -sf "$SWAYNC_SRC" "$SWAYNC_DEST"

    necro_print "swaync" "Notification relay linked — editing ~/.config/swaync edits the repo."
}
