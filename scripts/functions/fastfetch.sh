#!/usr/bin/env bash
# Necrodermis — scripts/functions/fastfetch.sh
# Component: install_fastfetch

install_fastfetch() {
    print_section "FASTFETCH  //  SYSTEM READOUT NODE"

    local SRC="$SCRIPT_DIR/configs/fastfetch"
    local DEST="$CONFIG_DIR/fastfetch"

    necro_print "fastfetch" "Deploying configuration..."

    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        necro_backup "$DEST"
    fi

    if [ -L "$DEST" ]; then
        rm "$DEST"
    fi

    necro_run mkdir -p "$DEST"
    necro_run cp -r "$SRC/." "$DEST/"

    necro_print "fastfetch" "Deployed — user-owned, not symlinked."
}
