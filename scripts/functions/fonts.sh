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

    # Set Iosevka as system default via fontconfig
    mkdir -p "$CONFIG_DIR/fontconfig"
    cp "$SCRIPT_DIR/configs/fontconfig/fonts.conf" "$CONFIG_DIR/fontconfig/fonts.conf"
    fc-cache -fv &>/dev/null
    print_ok "Iosevka set as system default  ${DG}//  fontconfig${NC}"
