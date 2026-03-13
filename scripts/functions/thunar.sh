#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/thunar.sh
# Component: install_thunar

install_thunar() {
    print_section "THUNAR  //  TOMB ARCHIVE INTERFACE"
    necro_pkg "thunar" \
        thunar \
        thunar-archive-plugin \
        thunar-volman \
        tumbler \
        ffmpegthumbnailer
    print_ok "Archive interface mounted  ${DG}//  thunar + plugins${NC}"
}
