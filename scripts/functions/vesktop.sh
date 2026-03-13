#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/vesktop.sh
# Component: install_vesktop

install_vesktop() {
    print_section "VESKTOP  //  DYNASTY COMMS CHANNEL"
    local AUR_HELPER
    AUR_HELPER="$(get_aur_helper)"
    if [ -z "$AUR_HELPER" ]; then
        print_err "No AUR helper available — skipping Vesktop"
        return 1
    fi
    $AUR_HELPER -S --needed --noconfirm vesktop-bin
    print_ok "Dynasty comms online  ${DG}//  vesktop-bin${NC}"
}
