#!/usr/bin/env bash
# Necrodermis — scripts/functions/cava.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_cava

install_cava() {
    print_section "CAVA  //  ACOUSTIC RESONANCE DISPLAY"
    backup_and_install "$SCRIPT_DIR/configs/cava/config" \
        "$CONFIG_DIR/cava/config" "acoustic resonance config"
}
