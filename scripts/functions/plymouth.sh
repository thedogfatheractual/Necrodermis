#!/usr/bin/env bash
# Necrodermis — scripts/functions/plymouth.sh
# Component: install_plymouth

install_plymouth() {
    print_section "PLYMOUTH  //  INITRAMFS SPLASH PROTOCOL"

    if [ ! -d "$SCRIPT_DIR/themes/plymouth/necrodermis" ]; then
        print_err "Plymouth theme source not found: $SCRIPT_DIR/themes/plymouth/necrodermis  //  skipping"
        return 0
    fi

    if ! command -v plymouth-set-default-theme &>/dev/null; then
        print_info "Plymouth not detected  //  dispatching scarabs to acquire..."
        local AUR_HELPER
        AUR_HELPER="$(get_aur_helper)"
        if ! sudo pacman -S --needed plymouth --noconfirm; then
            if [ -n "$AUR_HELPER" ]; then
                $AUR_HELPER -S --needed plymouth
            else
                print_err "Plymouth install failed — no AUR helper available  //  skipping"
                return 0
            fi
        fi
    fi

    sudo mkdir -p /usr/share/plymouth/themes/necrodermis
    sudo cp -r "$SCRIPT_DIR/themes/plymouth/necrodermis/." /usr/share/plymouth/themes/necrodermis/
    print_ok "Splash theme uploaded  ${DG}//  /usr/share/plymouth/themes/necrodermis${NC}"

    sudo plymouth-set-default-theme necrodermis
    print_ok "Default splash theme set  ${DG}//  necrodermis active${NC}"

    # ── INITRAMFS REBUILD ──
    if [ -f /etc/mkinitcpio.conf ]; then
        if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
            sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.necrodermis-backup
            sudo sed -i 's/\(HOOKS=.*\budev\b\)/\1 plymouth/' /etc/mkinitcpio.conf
            print_ok "plymouth injected into mkinitcpio HOOKS  ${DG}//  after udev${NC}"
        else
            print_info "plymouth already present in mkinitcpio HOOKS  //  skipping"
        fi
        print_info "Rebuilding initramfs  //  this will take a moment..."
        sudo mkinitcpio -P
        print_ok "Initramfs rebuilt  ${DG}//  splash protocol armed${NC}"
    elif command -v dracut &>/dev/null; then
        print_info "dracut detected  //  rebuilding initramfs..."
        # Ensure EFI output directories exist before dracut runs
        local kernel_ver
        kernel_ver=$(uname -r)
        local machine_id
        machine_id=$(cat /etc/machine-id 2>/dev/null || echo "")
        if [ -n "$machine_id" ]; then
            sudo mkdir -p "/boot/efi/${machine_id}/${kernel_ver}"
        fi
        if sudo dracut --force 2>&1; then
            print_ok "Initramfs rebuilt  ${DG}//  splash protocol armed${NC}"
        else
            print_err "dracut failed  //  splash will activate after manual initramfs rebuild"
            print_info "Run manually: sudo dracut --force"
        fi
    else
        print_err "Neither mkinitcpio nor dracut found  //  rebuild initramfs manually after install"
    fi
}
