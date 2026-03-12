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
    necro_pkg "base-prereqs" \
        base-devel \
        archlinux-keyring \
        findutils \
        curl \
        wget \
        unzip \
        git

    # ── Core Hyprland stack ───────────────────────────────────
    print_info "Deploying Hyprland cortex  //  primary tomb systems online..."
    necro_pkg_critical "hyprland-core" \
        hyprland \
        hypridle \
        hyprlock \
        xdg-desktop-portal-hyprland \
        xdg-user-dirs \
        xdg-utils

    print_info "Binding polkit servitor  //  authority protocols engaged..."
    necro_yay "hyprpolkitagent" hyprpolkitagent

    # ── Wayland plumbing ──────────────────────────────────────
    print_info "Routing Wayland conduits  //  signal architecture initialising..."
    necro_pkg_critical "wayland-plumbing" \
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

    # ── Audio / media ─────────────────────────────────────────
    print_info "Calibrating resonance arrays  //  audio substrate online..."
    necro_pkg "audio-media" \
        pamixer \
        pavucontrol \
        playerctl \
        mpv

    print_info "Binding mpris scarab  //  media control layer..."
    necro_yay "mpris-wlogout" mpv-mpris wlogout

    # ── System utilities ──────────────────────────────────────
    print_info "Deploying utility scarabs  //  tomb maintenance complement..."
    necro_pkg "system-utils" \
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
    necro_pkg "qt-theming" \
        qt5ct \
        qt6-svg \
        nwg-look \
        nwg-displays

    # ── Optional extras ───────────────────────────────────────
    print_info "Acquiring ancillary tomb complement  //  non-essential but worthy..."
    necro_pkg "optional-extras" \
        loupe \
        mousepad \
        nvtop \
        qalculate-gtk \
        yt-dlp

    print_info "Binding wallust chromatic array  //  colour extraction protocols..."
    necro_yay "wallust" wallust

    # ── Enable essential services ─────────────────────────────
    print_info "Awakening Pipewire servitors  //  audio daemons bound to the dynasty..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber \
        || necro_log "FAIL" "pipewire-services" "systemctl enable failed — may need manual enable after reboot"

    print_info "Establishing XDG territorial markers  //  directory hierarchy confirmed..."
    xdg-user-dirs-update \
        || necro_log "FAIL" "xdg-user-dirs" "xdg-user-dirs-update failed"

    print_ok "Hyprland substrate online  ${DG}//  the tomb world stirs${NC}"
}
