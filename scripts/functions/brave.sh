#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/brave.sh
# Component: install_brave

install_brave() {
    print_section "BRAVE  //  ENCRYPTED COMMS RELAY"
    local AUR_HELPER
    AUR_HELPER="$(get_aur_helper)"
    if [ -z "$AUR_HELPER" ]; then
        print_err "No AUR helper available — skipping Brave"
        return 1
    fi
    $AUR_HELPER -S --needed --noconfirm brave-bin
    print_ok "Comms relay online  ${DG}//  brave-bin${NC}"
}
