#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — install_hyprland_base
# Raises the full Hyprland substrate from bare metal.
# ════════════════════════════════════════════════════════════

install_hyprland_base() {
    print_section "HYPRLAND SUBSTRATE  //  TOMB WORLD AWAKENING PREREQUISITES"

    necro_tui_init \
        "base-prereqs|Base Prerequisites" \
        "spasskaya-clocks|Spasskaya Clocks" \
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

    # ── Spasskaya Clocks — optional ──────────────────────────
    necro_tui_stage_set "spasskaya-clocks" "ACTIVE"
    echo ""
    echo -e "  ${G}${B}  ┌─ Spasskaya Clocks  //  OPTIONAL ──────────────────────────────${NC}"
    echo -e "  ${DG}  │  Plays Kremlin clocktower chimes at :00 and :30 via cron.${NC}"
    echo -e "  ${DG}  │  Includes the Spasskaya Tower melody + hourly strikes.${NC}"
    echo -e "  ${DG}  │  Additional chime packs (Westminster etc) can be added later.${NC}"
    echo -e "  ${DG}  │  Requires: ffmpeg, cronie${NC}"
    echo -e "  ${G}${B}  └──────────────────────────────────────────────${NC}"
    echo ""

    local spas_choice
    if true; then
        spas_choice="NO"
        print_info "TTY mode  //  skipping Spasskaya Clocks"
    else
        spas_choice=$(
            gum choose \
                --header="  Install Spasskaya Clocks?" \
                --header.foreground="2" \
                --cursor.foreground="2" \
                --selected.foreground="2" \
                --item.foreground="7" \
                "  NO   —  skip for now" \
                "  YES  —  install clocktower chimes" \
            2>/dev/null
        ) || spas_choice="NO"
    fi

    if [[ "$spas_choice" == *"YES"* ]]; then
        necro_pkg "spasskaya-clocks" ffmpeg cronie
        local spas_tmp
        spas_tmp=$(mktemp -d)
        git clone --depth=1 git@github.com:thedogfatheractual/spasskaya-clocks.git "$spas_tmp" 2>/dev/null \
            || git clone --depth=1 https://github.com/thedogfatheractual/spasskaya-clocks.git "$spas_tmp"
        bash "$spas_tmp/install.sh" \
            && necro_log "OK" "spasskaya-clocks" "Clocktower chimes installed" \
            || necro_log "FAIL" "spasskaya-clocks" "Spasskaya install script failed"
        rm -rf "$spas_tmp"
        necro_tui_stage_set "spasskaya-clocks" "OK"
    else
        necro_log "SKIP" "spasskaya-clocks" "Spasskaya Clocks skipped by operator"
        necro_tui_stage_set "spasskaya-clocks" "SKIP"
        print_skip "Spasskaya Clocks  //  skipped"
    fi

    print_info "Deploying Hyprland cortex  //  primary tomb systems online..."
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
    print_info "Binding SDDM display manager  //  enabling on next boot..."
    sudo systemctl enable sddm \
        || necro_log "FAIL" "sddm" "systemctl enable sddm failed"
    necro_log "OK" "sddm" "SDDM enabled"
    print_ok "SDDM  ${DG}//  display manager enabled${NC}"

    print_ok "Hyprland substrate online  ${DG}//  the tomb world stirs${NC}"
    # Deploy autoupdate relay
    mkdir -p "$NECRO_HOME"
    cp "$SCRIPT_DIR/scripts/necro-autoupdate.sh" "$NECRO_HOME/necro-autoupdate.sh"
    chmod +x "$NECRO_HOME/necro-autoupdate.sh"
    print_ok "Canoptek update relay deployed  ${DG}//  $NECRO_HOME/necro-autoupdate.sh${NC}"
}
