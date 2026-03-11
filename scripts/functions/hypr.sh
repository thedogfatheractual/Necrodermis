#!/usr/bin/env bash
# Necrodermis — scripts/functions/hypr.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_hypr

install_hypr() {
    print_section "HYPRLAND  //  ENVIRONMENTAL CONTROL MATRIX"
    backup_and_install "$SCRIPT_DIR/configs/hypr/UserKeybinds.conf" \
        "$CONFIG_DIR/hypr/UserConfigs/UserKeybinds.conf" "command input matrix"
    backup_and_install "$SCRIPT_DIR/configs/hypr/UserDecorations.conf" \
        "$CONFIG_DIR/hypr/UserConfigs/UserDecorations.conf" "architectural overlays"
    backup_and_install "$SCRIPT_DIR/configs/hypr/01-UserDefaults.conf" \
        "$CONFIG_DIR/hypr/UserConfigs/01-UserDefaults.conf" "system defaults"
}
