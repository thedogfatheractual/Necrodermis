#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS  //  scripts/distro/arch.sh
# Arch / CachyOS / Manjaro bootstrap
# ════════════════════════════════════════════════════════════

necro_distro_bootstrap() {
    print_section "ARCH BOOTSTRAP  //  VERIFYING SUBSTRATE"

    # Pacman keyring — refresh before anything else
    print_info "Refreshing pacman keyring..."
    sudo pacman-key --init 2>/dev/null || true
    sudo pacman-key --populate 2>/dev/null || true

    # Sync repos
    sudo pacman -Sy --noconfirm 2>/dev/null || true

    # Ensure base-devel is present — needed for AUR builds
    if ! pacman -Q base-devel &>/dev/null; then
        print_info "Installing base-devel  //  required for AUR"
        sudo pacman -S --needed --noconfirm base-devel git
    fi

    # AUR helper
    if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
        print_info "No AUR helper found  //  acquiring yay"
        _bootstrap_install_yay
    else
        print_ok "AUR helper present  //  $(get_aur_helper)"
    fi

    print_ok "Arch bootstrap complete"
}

_bootstrap_install_yay() {
    local tmp
    tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" 2>/dev/null \
        && (cd "$tmp/yay-bin" && makepkg -si --noconfirm 2>/dev/null) \
        && print_ok "yay installed" \
        || print_err "yay install failed  //  AUR packages will be skipped"
    rm -rf "$tmp"
}
