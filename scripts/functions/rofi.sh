#!/usr/bin/env bash
# Necrodermis — scripts/functions/rofi.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_rofi

install_rofi() {
    print_section "ROFI  //  COMMAND INTERFACE OVERLAY"
    backup_and_install "$SCRIPT_DIR/configs/rofi/config.rasi" \
        "$CONFIG_DIR/rofi/config.rasi" "command interface config"
    backup_and_install "$SCRIPT_DIR/configs/rofi/necrodermis.rasi" \
        "$CONFIG_DIR/rofi/necrodermis.rasi" "necrodermis overlay theme"
}
