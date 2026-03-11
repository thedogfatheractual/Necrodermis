#!/usr/bin/env bash
# Necrodermis — scripts/functions/gtk.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_gtk

install_gtk() {
    print_section "GTK THEME  //  DERMAL LAYER INSTALLATION"
    sudo cp -r "$SCRIPT_DIR/themes/gtk/Necrodermis-green-Dark-compact" /usr/share/themes/
    gsettings set org.gnome.desktop.interface gtk-theme 'Necrodermis-green-Dark-compact' 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface gtk-theme 'Necrodermis-green-Dark-compact' 2>/dev/null || true
    backup_and_install "$SCRIPT_DIR/configs/gtk-3.0/gtk.css" "$CONFIG_DIR/gtk-3.0/gtk.css" "GTK3 dermal layer"
    backup_and_install "$SCRIPT_DIR/configs/gtk-4.0/gtk.css" "$CONFIG_DIR/gtk-4.0/gtk.css" "GTK4 dermal layer"
}
