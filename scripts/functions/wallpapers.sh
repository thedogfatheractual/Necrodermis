#!/usr/bin/env bash
# Necrodermis — scripts/functions/wallpapers.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_wallpapers

install_wallpapers() {
    print_section "WALLPAPERS  //  TOMB WORLD SURFACE RENDERING"
    mkdir -p "$WALLPAPER_DIR"
    cp "$SCRIPT_DIR/wallpapers/"* "$WALLPAPER_DIR/"
    print_ok "Surface renders installed  ${DG}//  $WALLPAPER_DIR${NC}"
    print_info "Personal wallpapers in ~/Pictures/wallpapers/ are untouched"
}
