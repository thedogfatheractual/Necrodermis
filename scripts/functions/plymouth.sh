#!/usr/bin/env bash
# Necrodermis — scripts/functions/plymouth.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_plymouth

install_plymouth() {
    print_section "PLYMOUTH  //  INITRAMFS SPLASH PROTOCOL"

    if [ ! -d "$SCRIPT_DIR/themes/plymouth/necrodermis" ]; then
        print_err "Plymouth theme source not found: $SCRIPT_DIR/themes/plymouth/necrodermis"
        return 1
    fi

    if ! command -v plymouth-set-default-theme &>/dev/null; then
        print_info "Plymouth not detected  //  dispatching scarabs to acquire..."
        local AUR_HELPER
        AUR_HELPER="$(get_aur_helper)"
        if ! sudo pacman -S --needed plymouth --noconfirm; then
            if [ -n "$AUR_HELPER" ]; then
                $AUR_HELPER -S --needed plymouth
            else
                print_err "Plymouth install failed — no AUR helper available"
                print_info "Install manually: sudo pacman -S plymouth"
                return 1
            fi
        fi
    fi

    sudo mkdir -p /usr/share/plymouth/themes/necrodermis
    sudo cp -r "$SCRIPT_DIR/themes/plymouth/necrodermis/." /usr/share/plymouth/themes/necrodermis/
    print_ok "Splash theme uploaded  ${DG}//  /usr/share/plymouth/themes/necrodermis${NC}"

    sudo plymouth-set-default-theme necrodermis
    print_ok "Default splash theme set  ${DG}//  necrodermis active${NC}"

    # Inject plymouth into mkinitcpio HOOKS if not already present
    # Must appear after base and udev, before filesystems
    if grep -q "^HOOKS=" /etc/mkinitcpio.conf; then
        if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
            sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.necrodermis-backup
            sudo sed -i 's/\(HOOKS=.*\budev\b\)/\1 plymouth/' /etc/mkinitcpio.conf
            print_ok "plymouth injected into mkinitcpio HOOKS  ${DG}//  after udev${NC}"
        else
            print_info "plymouth already present in mkinitcpio HOOKS  //  skipping"
        fi
    else
        print_err "Could not find HOOKS= in /etc/mkinitcpio.conf — add plymouth manually"
    fi

    print_info "Rebuilding initramfs  //  this will take a moment..."
    sudo mkinitcpio -P
    print_ok "Initramfs rebuilt  ${DG}//  splash protocol armed${NC}"
}
