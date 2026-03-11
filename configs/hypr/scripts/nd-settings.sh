#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — ND-SETTINGS
# Defacto control panel — gum TUI
# ════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_SCRIPTS="$SCRIPT_DIR"
NECRO_REPO="$HOME/necrodermis"

G='\033[0;32m'
DG='\033[2;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[1m'
NC='\033[0m'

# ── STUBS ─────────────────────────────────────────────────────────────────────
menu_wallpaper()    { bash "$HYPR_SCRIPTS/WallpaperSelect.sh"; }
menu_hyprlock()     { bash "$HYPR_SCRIPTS/hyprlock.sh"; }
menu_monitors()     { bash "$HYPR_SCRIPTS/MonitorProfiles.sh"; }
menu_audio()        { bash "$HYPR_SCRIPTS/nd-volume.sh"; }
menu_kitty()        { bash "$HYPR_SCRIPTS/KittyTheme.sh"; }
menu_fish()         { kitty --title "fish-config" fish -c "vim ~/.config/fish/config.fish"; }
menu_animations()   { bash "$HYPR_SCRIPTS/Animations.sh"; }
menu_blur()         { bash "$HYPR_SCRIPTS/ChangeBlur.sh"; }
menu_darklight()    { bash "$HYPR_SCRIPTS/ThemeChanger.sh"; }
menu_gtk()          { bash "$HYPR_SCRIPTS/ThemeChanger.sh"; }
menu_keybinds()     { bash "$HYPR_SCRIPTS/KeyHints.sh"; }
menu_idle()         { bash "$HYPR_SCRIPTS/Hypridle.sh"; }
menu_dnd()          { bash "$HYPR_SCRIPTS/swaync-client -t"; }
menu_update()       { bash "$NECRO_REPO/configs/hypr/scripts/nd-update.sh" --both; }
menu_restore()      { bash "$NECRO_REPO/nd-restore.sh"; }

# ── MAIN MENU ─────────────────────────────────────────────────────────────────
while true; do
    choice=$(gum choose \
        --header "  NECRODERMIS  //  CONTROL PANEL" \
        "  Wallpaper" \
        "  Hyprlock" \
        "  Monitors" \
        "  Audio" \
        "  Kitty" \
        "  Fish" \
        "  Animations" \
        "  Blur" \
        "  Dark / Light" \
        "  GTK / Qt" \
        "  Keybinds" \
        "  Idle / Lock" \
        "  Do Not Disturb" \
        "  Update / Clean" \
        "  Restore Configs" \
        "  Exit" \
    ) || exit 0

    case "$choice" in
        *Wallpaper*)    menu_wallpaper ;;
        *Hyprlock*)     menu_hyprlock ;;
        *Monitors*)     menu_monitors ;;
        *Audio*)        menu_audio ;;
        *Kitty*)        menu_kitty ;;
        *Fish*)         menu_fish ;;
        *Animations*)   menu_animations ;;
        *Blur*)         menu_blur ;;
        *"Dark / Light"*) menu_darklight ;;
        *"GTK / Qt"*)   menu_gtk ;;
        *Keybinds*)     menu_keybinds ;;
        *"Idle / Lock"*) menu_idle ;;
        *"Do Not Disturb"*) menu_dnd ;;
        *"Update / Clean"*) menu_update ;;
        *"Restore Configs"*) menu_restore ;;
        *Exit*)         exit 0 ;;
    esac
done
