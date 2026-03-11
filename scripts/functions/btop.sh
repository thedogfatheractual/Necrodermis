#!/usr/bin/env bash
# Necrodermis — scripts/functions/btop.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_btop

install_btop() {
    print_section "BTOP  //  CANOPTEK PROCESS MONITOR"
    backup_and_install "$SCRIPT_DIR/configs/btop/btop.conf" \
        "$CONFIG_DIR/btop/btop.conf" "process monitor config"
    mkdir -p "$CONFIG_DIR/btop/themes"
    backup_and_install "$SCRIPT_DIR/configs/btop/necrodermis.theme" \
        "$CONFIG_DIR/btop/themes/necrodermis.theme" "process monitor skin"
}
