#!/usr/bin/env bash
# Necrodermis — scripts/functions/waybar.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_waybar

install_waybar() {
    print_section "WAYBAR  //  STATUS ARRAY CALIBRATION"
    backup_and_install "$SCRIPT_DIR/configs/waybar/config" \
        "$CONFIG_DIR/waybar/config" "status array config"
    backup_and_install "$SCRIPT_DIR/configs/waybar/style.css" \
        "$CONFIG_DIR/waybar/style.css" "status array skin"
}
