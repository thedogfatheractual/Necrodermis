#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — install_hyprland_base
# Raises the full Hyprland substrate from bare metal.
# ════════════════════════════════════════════════════════════

install_hyprland_base() {
    print_section "HYPRLAND SUBSTRATE  //  TOMB WORLD AWAKENING PREREQUISITES"

    necro_tui_init \
        "base-prereqs|Base Prerequisites" \
        "hyprland-core|Hyprland Core" \
        "hyprpolkitagent|Polkit Agent" \
        "wayland-plumbing|Wayland Plumbing" \
        "audio-media|Audio + Media" \
        "mpris-wlogout|MPRIS + Wlogout" \
        "system-utils|System Utilities" \
        "qt-theming|Qt Theming" \
        "optional-extras|Optional Extras" \
        "wallust|Wallust"

    print_info "Requisitioning base materiel  //  stasis inventory check..."
    necro_tui_stage_set "base-prereqs" "ACTIVE"
    necro_pkg "base-prereqs" base-devel archlinux-keyring findutils curl wget unzip git tmux
    necro_tui_stage_set "base-prereqs" "OK"

    print_info "Deploying Hyprland cortex  //  primary tomb systems online..."
    necro_tui_stage_set "hyprland-core" "ACTIVE"
    necro_pkg_critical "hyprland-core" \
        hyprland hypridle hyprlock xdg-desktop-portal-hyprland xdg-user-dirs xdg-utils kitty
    necro_tui_stage_set "hyprland-core" "OK"

    print_info "Binding polkit servitor  //  authority protocols engaged..."
    necro_tui_stage_set "hyprpolkitagent" "ACTIVE"
    necro_yay "hyprpolkitagent" hyprpolkitagent
    necro_tui_stage_set "hyprpolkitagent" "OK"

    print_info "Routing Wayland conduits  //  signal architecture initialising..."
    necro_tui_stage_set "wayland-plumbing" "ACTIVE"
    necro_pkg_critical "wayland-plumbing" \
        pipewire pipewire-audio pipewire-pulse wireplumber \
        grim slurp swappy swww wl-clipboard cliphist
    necro_tui_stage_set "wayland-plumbing" "OK"

    print_info "Calibrating resonance arrays  //  audio substrate online..."
    necro_tui_stage_set "audio-media" "ACTIVE"
    necro_pkg "audio-media" pamixer pavucontrol playerctl mpv
    necro_tui_stage_set "audio-media" "OK"

    print_info "Binding mpris scarab  //  media control layer..."
    necro_tui_stage_set "mpris-wlogout" "ACTIVE"
    necro_yay "mpris-wlogout" mpv-mpris wlogout
    necro_tui_stage_set "mpris-wlogout" "OK"

    print_info "Deploying utility scarabs  //  tomb maintenance complement..."
    necro_tui_stage_set "system-utils" "ACTIVE"
    necro_pkg "system-utils" \
        bc imagemagick inxi jq libspng network-manager-applet \
        pacman-contrib python-requests python-pyquery \
        gvfs gvfs-mtp brightnessctl yad
    necro_tui_stage_set "system-utils" "OK"

    print_info "Applying Qt dermal substrate  //  visual cortex preparation..."
    necro_tui_stage_set "qt-theming" "ACTIVE"
    necro_pkg "qt-theming" qt5ct qt6-svg nwg-look nwg-displays
    necro_tui_stage_set "qt-theming" "OK"

    print_info "Acquiring ancillary tomb complement  //  non-essential but worthy..."
    necro_group_install "Optional Extras" "optional-extras" "pacman" \
        loupe mousepad nvtop qalculate-gtk yt-dlp

    print_info "Binding wallust chromatic array  //  colour extraction protocols..."
    necro_tui_stage_set "wallust" "ACTIVE"
    necro_yay "wallust" wallust
    necro_tui_stage_set "wallust" "OK"

    print_info "Awakening Pipewire servitors  //  audio daemons bound to the dynasty..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber \
        || necro_log "FAIL" "pipewire-services" "systemctl enable failed — manual enable required after reboot"

    print_info "Establishing XDG territorial markers  //  directory hierarchy confirmed..."
    xdg-user-dirs-update \
        || necro_log "FAIL" "xdg-user-dirs" "xdg-user-dirs-update failed"

    print_ok "Hyprland substrate online  ${DG}//  the tomb world stirs${NC}"
}
