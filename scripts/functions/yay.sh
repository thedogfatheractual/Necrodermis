#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/yay.sh
# Component: install_yay

install_yay() {
    print_section "YAY  //  AUR HELPER ACQUISITION"

    if command -v yay &>/dev/null; then
        print_ok "yay already present  ${DG}//  skipping${NC}"
        YAY_AVAILABLE=true
        return
    fi

    if command -v paru &>/dev/null; then
        print_ok "paru detected  ${DG}//  AUR helper already available${NC}"
        YAY_AVAILABLE=true
        return
    fi

    print_info "No AUR helper found  //  deploying yay..."

    sudo pacman -S --needed base-devel rust git --noconfirm

    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    cd "$tmp_dir/yay"
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$tmp_dir"

    if command -v yay &>/dev/null; then
        YAY_AVAILABLE=true
        print_ok "yay installed  ${DG}//  AUR access online${NC}"
    else
        necro_log "FAIL" "yay" "yay build completed but binary not found in PATH"
        print_err "yay install failed  //  AUR packages will be skipped"
    fi
}
