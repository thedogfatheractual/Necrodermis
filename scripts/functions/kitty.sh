#!/usr/bin/env bash
# Necrodermis — scripts/functions/kitty.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_kitty

install_kitty() {
    print_section "KITTY  //  TERMINAL INTERFACE NODE"
    backup_and_install "$SCRIPT_DIR/configs/kitty/kitty.conf" \
        "$CONFIG_DIR/kitty/kitty.conf" "terminal node config"
    # Copy necrodermis colour theme — kitty.conf includes it via ./kitty-themes/necrodermis.conf
    mkdir -p "$CONFIG_DIR/kitty/kitty-themes"
    if [ -f "$SCRIPT_DIR/configs/kitty/kitty-themes/necrodermis.conf" ]; then
        cp "$SCRIPT_DIR/configs/kitty/kitty-themes/necrodermis.conf" \
            "$CONFIG_DIR/kitty/kitty-themes/necrodermis.conf"
        print_ok "Sautekh colour theme installed  ${DG}//  kitty-themes/necrodermis.conf${NC}"
    else
        print_err "necrodermis.conf not found in kitty-themes — terminal colours may be wrong"
    fi
}
