#!/usr/bin/env bash
# Necrodermis — scripts/functions/icons.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_icons

install_icons() {
    print_section "ICON THEME  //  VISUAL RECOGNITION MATRIX"
    sudo cp -r "$SCRIPT_DIR/icons/Flat-Remix-Necrodermis" /usr/share/icons/
    gsettings set org.gnome.desktop.interface icon-theme 'Flat-Remix-Necrodermis' 2>/dev/null || true
    print_ok "Visual recognition matrix uploaded  ${DG}//  icons synchronised${NC}"
}
