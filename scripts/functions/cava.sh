#!/usr/bin/env bash
# Necrodermis — scripts/functions/cava.sh
# Component: install_cava

install_cava() {
    print_section "CAVA  //  AUDIO VISUALISER NODE"

    necro_pkg "cava" cava

    local SRC="$SCRIPT_DIR/configs/cava"
    local DEST="$CONFIG_DIR/cava"

    necro_print "cava" "Deploying configuration..."

    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        necro_backup "$DEST"
    fi

    if [ -L "$DEST" ]; then
        rm "$DEST"
    fi

    necro_run mkdir -p "$DEST"
    necro_run cp -r "$SRC/." "$DEST/"

    necro_print "cava" "Deployed — user-owned, not symlinked."
}
