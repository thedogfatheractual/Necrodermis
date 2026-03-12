#!/usr/bin/env bash
# Necrodermis — scripts/functions/rofi.sh
# Component: install_rofi

install_rofi() {
    print_section "ROFI  //  COMMAND INTERFACE NODE"

    necro_pkg "rofi" rofi rofi-wayland

    local ROFI_SRC="$SCRIPT_DIR/configs/rofi"
    local ROFI_DEST="$CONFIG_DIR/rofi"

    necro_print "rofi" "Deploying command interface configuration..."

    if [ -d "$ROFI_DEST" ] && [ ! -L "$ROFI_DEST" ]; then
        necro_backup "$ROFI_DEST"
    fi

    if [ -L "$ROFI_DEST" ]; then
        rm "$ROFI_DEST"
    fi

    necro_run ln -sf "$ROFI_SRC" "$ROFI_DEST"

    necro_print "rofi" "Command interface linked — editing ~/.config/rofi edits the repo."
}
