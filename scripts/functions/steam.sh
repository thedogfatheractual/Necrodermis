#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/steam.sh
# Component: install_steam

install_steam() {
    print_section "STEAM  //  TOMB WORLD RECREATION ARRAY"
    # Ensure multilib is enabled
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
        sudo pacman -Sy --noconfirm
    fi
    necro_pkg "steam" steam
    print_ok "Recreation array armed  ${DG}//  steam${NC}"
}
