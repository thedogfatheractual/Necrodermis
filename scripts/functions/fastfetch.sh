#!/usr/bin/env bash
# Necrodermis — scripts/functions/fastfetch.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_fastfetch

install_fastfetch() {
    print_section "FASTFETCH  //  SYSTEM MANIFEST DISPLAY"
    backup_and_install "$SCRIPT_DIR/configs/fastfetch/config.jsonc" \
        "$CONFIG_DIR/fastfetch/config.jsonc" "manifest config"
    backup_and_install "$SCRIPT_DIR/configs/fastfetch/necron-warrior-final.txt" \
        "$CONFIG_DIR/fastfetch/necron-warrior-final.txt" "necron warrior sigil"
}
