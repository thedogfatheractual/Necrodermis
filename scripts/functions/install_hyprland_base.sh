#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — install_hyprland_base
# Raises the full Hyprland substrate from bare metal.
# The JaKooLit dependency is heresy. It has been purged.
# ════════════════════════════════════════════════════════════

install_hyprland_base() {
    NECRO_STAGE_CURRENT=0
    NECRO_STAGE_TOTAL=11
    print_section "HYPRLAND SUBSTRATE  //  TOMB WORLD AWAKENING PREREQUISITES"

    # ── System prereqs ────────────────────────────────────────
    print_info "Requisitioning base materiel  //  stasis inventory check..."
    necro_group_install "Base Prerequisites" "base-prereqs" "pacman" \
        base-devel \
        archlinux-keyring \
        findutils \
        curl \
        wget \
        unzip \
        git

    # ── Core Hyprland stack ───────────────────────────────────
    print_info "Deploying Hyprland cortex  //  primary tomb systems online..."
    necro_group_install "Hyprland Core" "hyprland-core" "pacman_critical" \
        hyprland \
        hypridle \
        hyprlock \
        xdg-desktop-portal-hyprland \
        xdg-user-dirs \
        xdg-utils

    print_info "Binding polkit servitor  //  authority protocols engaged..."
    necro_group_install "Polkit Agent" "hyprpolkitagent" "yay" \
        hyprpolkitagent

    # ── Wayland plumbing ──────────────────────────────────────
    print_info "Routing Wayland conduits  //  signal architecture initialising..."
    necro_group_install "Wayland Plumbing" "wayland-plumbing" "pacman_critical" \
        pipewire \
        pipewire-audio \
        pipewire-pulse \
        wireplumber \
        grim \
        slurp \
        swappy \
        swww \
        wl-clipboard \
        cliphist

    # ── Kitty terminal ────────────────────────────────────────
    print_info "Raising Canoptek terminal interface  //  kitty substrate binding..."
    necro_group_install "Kitty Terminal" "kitty" "pacman" \
        kitty

    # ── Audio / media ─────────────────────────────────────────
    print_info "Calibrating resonance arrays  //  audio substrate online..."
    necro_group_install "Audio + Media" "audio-media" "pacman" \
        pamixer \
        pavucontrol \
        playerctl \
        mpv

    print_info "Binding mpris scarab  //  media control layer..."
    necro_group_install "MPRIS + Wlogout" "mpris-wlogout" "yay" \
        mpv-mpris \
        wlogout

    # ── System utilities ──────────────────────────────────────
    print_info "Deploying utility scarabs  //  tomb maintenance complement..."
    necro_group_install "System Utilities" "system-utils" "pacman" \
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
    necro_group_install "Qt Theming" "qt-theming" "pacman" \
        qt5ct \
        qt6-svg \
        nwg-look \
        nwg-displays

    # ── Optional extras ───────────────────────────────────────
    print_info "Acquiring ancillary tomb complement  //  non-essential but worthy..."
    necro_group_install "Optional Extras" "optional-extras" "pacman" \
        loupe \
        mousepad \
        nvtop \
        qalculate-gtk \
        yt-dlp

    print_info "Binding wallust chromatic array  //  colour extraction protocols..."
    necro_group_install "Wallust" "wallust" "yay" \
        wallust

    # ── Enable essential services ─────────────────────────────
    print_info "Awakening Pipewire servitors  //  audio daemons bound to the dynasty..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber \
        || necro_log "FAIL" "pipewire-services" "systemctl enable failed — may need manual enable after reboot"

    print_info "Establishing XDG territorial markers  //  directory hierarchy confirmed..."
    xdg-user-dirs-update \
        || necro_log "FAIL" "xdg-user-dirs" "xdg-user-dirs-update failed"

    print_ok "Hyprland substrate online  ${DG}//  the tomb world stirs${NC}"
}
