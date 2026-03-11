#!/usr/bin/env bash
# Necrodermis — scripts/functions/qt.sh
# Component: install_qt

install_qt() {
    print_section "QT  //  INTERFACE STYLING NODE"

    local SRC="$SCRIPT_DIR/configs/qt"
    local DEST="$CONFIG_DIR/qt"

    necro_print "qt" "Deploying configuration..."

    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        necro_backup "$DEST"
    fi

    if [ -L "$DEST" ]; then
        rm "$DEST"
    fi

    necro_run mkdir -p "$DEST"
    necro_run cp -r "$SRC/." "$DEST/"

    necro_print "qt" "Deployed — user-owned, not symlinked."
}
