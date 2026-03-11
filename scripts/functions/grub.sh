#!/usr/bin/env bash
# Necrodermis — scripts/functions/grub.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_grub

install_grub() {
    print_section "GRUB  //  BOOT SEQUENCE OVERRIDE"

    if [ ! -d "$SCRIPT_DIR/themes/grub/necrodermis" ]; then
        print_err "GRUB theme source not found: $SCRIPT_DIR/themes/grub/necrodermis"
        return 1
    fi

    sudo mkdir -p /boot/grub/themes/necrodermis
    sudo cp -r "$SCRIPT_DIR/themes/grub/necrodermis/." /boot/grub/themes/necrodermis/
    print_ok "Boot theme uploaded  ${DG}//  /boot/grub/themes/necrodermis${NC}"

    # Backup existing grub defaults, then set GRUB_THEME
    if [ -f /etc/default/grub ]; then
        sudo cp /etc/default/grub /etc/default/grub.necrodermis-backup
        print_info "Previous /etc/default/grub archived  //  grub.necrodermis-backup"
        if grep -q "^GRUB_THEME=" /etc/default/grub; then
            sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/necrodermis/theme.txt"|' /etc/default/grub
        else
            echo 'GRUB_THEME="/boot/grub/themes/necrodermis/theme.txt"' | sudo tee -a /etc/default/grub > /dev/null
        fi
    else
        print_err "/etc/default/grub not found — is GRUB installed?"
        return 1
    fi
    print_ok "Boot theme registered  ${DG}//  /etc/default/grub updated${NC}"

    print_info "Regenerating boot configuration  //  stand by..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    print_ok "Boot configuration updated  ${DG}//  necrodermis theme armed${NC}"
}
