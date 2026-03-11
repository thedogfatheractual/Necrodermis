#!/usr/bin/env bash
# Necrodermis — scripts/functions/fish.sh
# Component: install_fish

install_fish() {
    print_section "FISH  //  SHELL INTERFACE NODE"

    local SRC="$SCRIPT_DIR/configs/fish"
    local DEST="$CONFIG_DIR/fish"

    necro_print "fish" "Deploying configuration..."

    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        necro_backup "$DEST"
    fi

    if [ -L "$DEST" ]; then
        rm "$DEST"
    fi

    necro_run mkdir -p "$DEST"
    necro_run cp -r "$SRC/." "$DEST/"

    necro_print "fish" "Deployed — user-owned, not symlinked."
}
