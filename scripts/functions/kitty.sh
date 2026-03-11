#!/usr/bin/env bash
# Necrodermis — scripts/functions/kitty.sh
# Component: install_kitty

install_kitty() {
    print_section "KITTY  //  TERMINAL INTERFACE NODE"

    local KITTY_SRC="$SCRIPT_DIR/configs/kitty"
    local KITTY_DEST="$CONFIG_DIR/kitty"

    necro_print "kitty" "Deploying terminal interface configuration..."

    if [ -d "$KITTY_DEST" ] && [ ! -L "$KITTY_DEST" ]; then
        necro_backup "$KITTY_DEST"
    fi

    if [ -L "$KITTY_DEST" ]; then
        rm "$KITTY_DEST"
    fi

    necro_run mkdir -p "$KITTY_DEST"
    necro_run cp -r "$KITTY_SRC/." "$KITTY_DEST/"

    necro_print "kitty" "Terminal interface deployed — user-owned, not symlinked."
}
