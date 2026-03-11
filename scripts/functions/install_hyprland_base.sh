#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — install_hyprland_base
# Raises the full Hyprland substrate from bare metal.
# The JaKooLit dependency is heresy. It has been purged.
# ════════════════════════════════════════════════════════════

install_hyprland_base() {
    print_section "HYPRLAND SUBSTRATE  //  TOMB WORLD AWAKENING PREREQUISITES"

    # ── System prereqs ────────────────────────────────────────
    print_info "Requisitioning base materiel  //  stasis inventory check..."
    sudo pacman -S --needed --noconfirm \
        base-devel \
        archlinux-keyring \
        findutils \
        curl \
        wget \
        unzip \
        git

    # ── Core Hyprland stack ───────────────────────────────────
    print_info "Deploying Hyprland cortex  //  primary tomb systems online..."
    sudo pacman -S --needed --noconfirm \
        hyprland \
        hypridle \
        hyprlock \
        xdg-desktop-portal-hyprland \
        xdg-user-dirs \
        xdg-utils

    print_info "Binding polkit servitor  //  authority protocols engaged..."
    yay -S --needed --noconfirm hyprpolkitagent

    # ── Wayland plumbing ──────────────────────────────────────
    print_info "Routing Wayland conduits  //  signal architecture initialising..."
    sudo pacman -S --needed --noconfirm \
        pipewire \
        pipewire-audio \
        pipewire-pulse \
        wireplumber \
        grim \
        slurp \
        swappy \
        swww \
        wl-clipboard \
        cliphist \

    # ── Audio / media ─────────────────────────────────────────
    print_info "Calibrating resonance arrays  //  audio substrate online..."
    sudo pacman -S --needed --noconfirm \
        pamixer \
        pavucontrol \
        playerctl \
        mpv

    print_info "Binding mpris scarab  //  media control layer..."
    yay -S --needed --noconfirm mpv-mpris wlogout

    # ── System utilities ──────────────────────────────────────
    print_info "Deploying utility scarabs  //  tomb maintenance complement..."
    sudo pacman -S --needed --noconfirm \
        bc \
        imagemagick \
        inxi \
        jq \
        libspng \
        network-manager-applet \
        pacman-contrib \
        python-requests \
        python-pyquery \
        gvfs \
        gvfs-mtp \
        brightnessctl \
        yad

    # ── Qt theming support ────────────────────────────────────
    print_info "Applying Qt dermal substrate  //  visual cortex preparation..."
    sudo pacman -S --needed --noconfirm \
        qt5ct \
        qt6-svg \
        nwg-look \
        nwg-displays

    # ── Optional extras ───────────────────────────────────────
    print_info "Acquiring ancillary tomb complement  //  non-essential but worthy..."
    sudo pacman -S --needed --noconfirm \
        loupe \
        mousepad \
        nvtop \
        qalculate-gtk \
        yt-dlp

    print_info "Binding wallust chromatic array  //  colour extraction protocols..."
    yay -S --needed --noconfirm wallust

    # ── Enable essential services ─────────────────────────────
    print_info "Awakening Pipewire servitors  //  audio daemons bound to the dynasty..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber

    print_info "Establishing XDG territorial markers  //  directory hierarchy confirmed..."
    xdg-user-dirs-update

    print_ok "Hyprland substrate online  ${DG}//  the tomb world stirs${NC}"
}
