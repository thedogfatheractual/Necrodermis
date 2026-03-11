#!/usr/bin/env bash
# Necrodermis — scripts/functions/qt.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_qt

install_qt() {
    print_section "QT6 / KVANTUM  //  SECONDARY DERMAL LAYER"
    mkdir -p "$CONFIG_DIR/Kvantum"
    backup_and_install "$SCRIPT_DIR/configs/kvantum/necrodermis.kvconfig" \
        "$CONFIG_DIR/Kvantum/necrodermis.kvconfig" "Kvantum dermal config"
    backup_and_install "$SCRIPT_DIR/configs/qt6ct/qt6ct.conf" \
        "$CONFIG_DIR/qt6ct/qt6ct.conf" "Qt6 rendering config"
}
