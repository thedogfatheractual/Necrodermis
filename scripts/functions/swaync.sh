#!/usr/bin/env bash
# Necrodermis — scripts/functions/swaync.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_swaync

install_swaync() {
    print_section "SWAYNC  //  COMMUNICATION ARRAY"
    backup_and_install "$SCRIPT_DIR/configs/swaync/config.json" \
        "$CONFIG_DIR/swaync/config.json" "communication array config"
    backup_and_install "$SCRIPT_DIR/configs/swaync/style.css" \
        "$CONFIG_DIR/swaync/style.css" "communication array skin"
    swaync-client --reload-config 2>/dev/null \
        && print_ok "Communication array reloaded  ${DG}//  transmissions nominal${NC}" \
        || true
}
