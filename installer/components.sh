#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — COMPONENT DEFINITIONS
# Add a component: one entry in COMPONENTS array + a matching
# function file in scripts/functions/install_<name>.sh
# ════════════════════════════════════════════════════════════
#
# Format: "NAME|CATEGORY|DESCRIPTION|FUNCTION"
# CATEGORIES: CORE  VISUAL  SYSTEM  EXTRAS

COMPONENTS=(
    "Hyprland|CORE|Keybinds, decorations, window rules|install_hypr"
    "Hyprlock|CORE|Screen locker configuration|install_hyprlock"
    "Waybar|CORE|Status bar|install_waybar"
    "Rofi|CORE|Launcher / command interface|install_rofi"
    "Kitty|CORE|Terminal|install_kitty"
    "Fish|CORE|Shell configuration|install_fish"
    "Fastfetch|CORE|System manifest display|install_fastfetch"
    "Swaync|CORE|Notification centre|install_swaync"
    "GTK|VISUAL|necrodermis-green-dark-compact|install_gtk"
    "Qt6 / Kvantum|VISUAL|Qt application skin|install_qt"
    "Icons|VISUAL|flat-remix-necrodermis|install_icons"
    "Wallpapers|VISUAL|Necron art collection|install_wallpapers"
    "Btop|VISUAL|Process monitor|install_btop"
    "Cava|VISUAL|Audio visualiser|install_cava"
    "SDDM|VISUAL|Tomb world login interface|install_sddm"
    "GRUB|VISUAL|Boot sequence override|install_grub"
    "Plymouth|VISUAL|Initramfs awakening sequence|install_plymouth"
    "Firewall|SYSTEM|ufw deny-incoming, LAN rules for Steam/Sunshine|install_firewall"
    "Hardening|SYSTEM|Kernel params, root lock, hidepid|install_hardening"
    "Sitrep|EXTRAS|METAR weather for SDDM and terminal|install_sitrep"
    "CachyOS Repos|EXTRAS|Optimised packages, kernel, schedulers — v3/v4 CPUs only|install_cachyos_repos"
)
