#!/usr/bin/env bash
# Necrodermis — scripts/functions/yay.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_yay

install_yay() {
    print_section "YAY  //  AUR HELPER ACQUISITION"

    if command -v yay &>/dev/null; then
        print_ok "yay already present  ${DG}//  skipping${NC}"
        return
    fi

    if command -v paru &>/dev/null; then
        print_ok "paru detected  ${DG}//  AUR helper already available${NC}"
        return
    fi

    print_info "No AUR helper found  //  deploying yay..."

    if ! command -v git &>/dev/null; then
        sudo pacman -S git --noconfirm
    fi

    sudo pacman -S --needed base-devel --noconfirm

    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    cd "$tmp_dir/yay"
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$tmp_dir"

    print_ok "yay installed  ${DG}//  AUR access online${NC}"
}
