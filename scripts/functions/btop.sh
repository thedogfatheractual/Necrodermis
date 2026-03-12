#!/usr/bin/env bash
# Necrodermis — scripts/functions/btop.sh
# Component: install_btop

install_btop() {
    print_section "BTOP  //  PROCESS MONITOR NODE"

    necro_pkg "btop" btop

    local SRC="$SCRIPT_DIR/configs/btop"
    local DEST="$CONFIG_DIR/btop"

    necro_print "btop" "Deploying configuration..."

    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        necro_backup "$DEST"
    fi

    if [ -L "$DEST" ]; then
        rm "$DEST"
    fi

    necro_run mkdir -p "$DEST"
    necro_run cp -r "$SRC/." "$DEST/"

    necro_print "btop" "Deployed — user-owned, not symlinked."
}
