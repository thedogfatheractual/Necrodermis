#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — install_hyprland_base
# Installs the full Hyprland dependency stack from bare Arch.
# Replaces the JaKooLit installer dependency entirely.
# ════════════════════════════════════════════════════════════

install_hyprland_base() {
    nd_print_section "Hyprland Base"

    # ── System prereqs ────────────────────────────────────────
    local base_pkgs=(
        base-devel
        archlinux-keyring
        findutils
        curl
        wget
        unzip
        git
    )

    # ── Core Hyprland stack ───────────────────────────────────
    local hypr_core=(
        hyprland
        hypridle
        hyprlock
        hyprpolkitagent      # polkit agent for Hyprland
        xdg-desktop-portal-hyprland
        xdg-user-dirs
        xdg-utils
    )

    # ── Wayland plumbing ──────────────────────────────────────
    local wayland_pkgs=(
        pipewire
        pipewire-audio
        pipewire-pulse
        wireplumber
        grim                 # screenshot
        slurp                # region select
        swappy               # screenshot annotation
        swww                 # wallpaper daemon
        wl-clipboard
        cliphist             # clipboard history
        wlogout
    )

    # ── Audio / media ─────────────────────────────────────────
    local audio_pkgs=(
        pamixer
        pavucontrol
        playerctl
        mpv
        mpv-mpris
    )

    # ── System utilities ─────────────────────────────────────
    local util_pkgs=(
        bc
        imagemagick
        inxi
        jq
        libspng
        network-manager-applet
        pacman-contrib
        python-requests
        python-pyquery
        gvfs
        gvfs-mtp
        brightnessctl
        yad
    )

    # ── Qt theming support ────────────────────────────────────
    local qt_pkgs=(
        qt5ct
        qt6-svg
        nwg-look
        nwg-displays
    )

    # ── Optional extras ───────────────────────────────────────
    local extras=(
        loupe
        mousepad
        nvtop
        qalculate-gtk
        yt-dlp
        wallust
    )

    # ── Install all groups ────────────────────────────────────
    nd_print_info "Installing base system prereqs..."
    backup_and_install "${base_pkgs[@]}"

    nd_print_info "Installing Hyprland core..."
    backup_and_install "${hypr_core[@]}"

    nd_print_info "Installing Wayland plumbing..."
    backup_and_install "${wayland_pkgs[@]}"

    nd_print_info "Installing audio stack..."
    backup_and_install "${audio_pkgs[@]}"

    nd_print_info "Installing system utilities..."
    backup_and_install "${util_pkgs[@]}"

    nd_print_info "Installing Qt theming support..."
    backup_and_install "${qt_pkgs[@]}"

    nd_print_info "Installing extras..."
    backup_and_install "${extras[@]}"

    # ── Enable essential services ─────────────────────────────
    nd_print_info "Enabling Pipewire user services..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber

    nd_print_info "Generating XDG user directories..."
    xdg-user-dirs-update

    nd_print_ok "Hyprland base installation complete."
}
