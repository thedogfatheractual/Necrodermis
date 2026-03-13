#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/fonts.sh
# Component: install_fonts

install_fonts() {
    print_section "FONTS  //  GLYPH SUBSTRATE LAYER"

    necro_pkg "fonts" \
        ttf-terminus-nerd \
        ttf-iosevka-nerd \
        ttf-sourcecodepro-nerd \
        ttf-meslo-nerd-font-powerlevel10k

    fc-cache -fv &>/dev/null
    print_ok "Glyph substrate loaded  ${DG}//  Terminess · Iosevka · SourceCodePro · Meslo${NC}"
}
