#!/usr/bin/env bash
# Necrodermis — scripts/functions/qt.sh
# Component: install_qt

install_qt() {
    print_section "QT  //  INTERFACE STYLING NODE"

    necro_print "qt" "Deploying configuration..."

    for component in qt5ct qt6ct Kvantum; do
        local SRC="$SCRIPT_DIR/configs/$component"
        local DEST="$CONFIG_DIR/$component"

        if [ ! -d "$SRC" ]; then
            necro_print "qt" "  skipped $component — source not found"
            continue
        fi

        if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
            necro_backup "$DEST"
        fi

        if [ -L "$DEST" ]; then
            rm "$DEST"
        fi

        necro_run mkdir -p "$DEST"
        necro_run cp -r "$SRC/." "$DEST/"
        necro_print "qt" "  $component deployed — user-owned, not symlinked."
    done
}
