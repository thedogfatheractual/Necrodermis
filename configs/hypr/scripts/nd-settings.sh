#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — ND-SETTINGS
# Defacto control panel — gum TUI
# ════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_SCRIPTS="$SCRIPT_DIR"
NECRO_REPO="$HOME/necrodermis"
conf="$HOME/.config/hypr/conf"
user="$HOME/.config/hypr/user"
iDIR="$HOME/.config/swaync/images"

# load user defaults (term, editor etc)
tmp_config=$(mktemp)
sed 's/^\$//g; s/ = /=/g' "$HOME/.config/hypr/user/defaults.conf" > "$tmp_config"
source "$tmp_config"
rm -f "$tmp_config"

# ── HELPERS ──────────────────────────────────────────────────────────────────
show_err() {
    notify-send -i "$iDIR/error.png" "NECRODERMIS" "$1" 2>/dev/null || echo "ERROR: $1"
}

show_info() {
    notify-send "NECRODERMIS" "$1" 2>/dev/null || echo "INFO: $1"
}

open_file() {
    local f="$1"
    if [ -f "$f" ]; then
        ${term:-kitty} -e ${edit:-vim} "$f"
    else
        show_err "File not found: $f"
    fi
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        show_err "Install $cmd first"
        return 1
    fi
}

# ── RAINBOW BORDERS ───────────────────────────────────────────────────────────
rainbow_borders_menu() {
    local rainbow_script="$HOME/.config/hypr/user-scripts/RainbowBorders.sh"
    local disabled_bak="${rainbow_script}.bak"
    local refresh_script="$HYPR_SCRIPTS/Refresh.sh"

    local current="disabled"
    if [[ -f "$rainbow_script" ]]; then
        current=$(grep -E '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null | sed -E 's/^EFFECT_TYPE="?([^"]*)"?/\1/')
        [[ -z "$current" ]] && current="unknown"
    fi

    local current_display
    case "$current" in
        wallust_random) current_display="Wallust Colour" ;;
        rainbow)        current_display="Original Rainbow" ;;
        gradient_flow)  current_display="Gradient Flow" ;;
        *)              current_display="Disabled" ;;
    esac

    local choice
    choice=$(printf "Disable\nWallust Colour\nOriginal Rainbow\nGradient Flow" | \
        gum choose --header "  RAINBOW BORDERS  //  current: $current_display")
    [[ -z "$choice" ]] && return

    case "$choice" in
        Disable)
            [[ -f "$rainbow_script" ]] && mv "$rainbow_script" "$disabled_bak"
            hyprctl reload >/dev/null 2>&1 || true
            ;;
        *)
            local mode
            case "$choice" in
                "Wallust Colour")   mode="wallust_random" ;;
                "Original Rainbow") mode="rainbow" ;;
                "Gradient Flow")    mode="gradient_flow" ;;
            esac
            if [[ ! -f "$rainbow_script" && -f "$disabled_bak" ]]; then
                mv "$disabled_bak" "$rainbow_script"
            fi
            if grep -q '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null; then
                sed -i 's/^EFFECT_TYPE=.*/EFFECT_TYPE="'"$mode"'"/' "$rainbow_script"
            else
                sed -i '1a EFFECT_TYPE="'"$mode"'"' "$rainbow_script"
            fi
            ;;
    esac
}

# ── SUBMENUS ──────────────────────────────────────────────────────────────────
menu_user_configs() {
    local choice
    choice=$(printf \
"Edit User Defaults\nEdit User Keybinds\nEdit User ENV Variables\nEdit User Startup Apps\nEdit User Window Rules\nEdit User Workspace Rules\nEdit User Settings\nEdit User Decorations\nEdit User Animations\nEdit User Laptop Settings" | \
        gum choose --header "  USER CONFIGS")
    [[ -z "$choice" ]] && return
    case "$choice" in
        "Edit User Defaults")        open_file "$user/defaults.conf" ;;
        "Edit User Keybinds")        open_file "$user/keybinds.conf" ;;
        "Edit User ENV Variables")   open_file "$user/env.conf" ;;
        "Edit User Startup Apps")    open_file "$user/startup.conf" ;;
        "Edit User Window Rules")    open_file "$user/windowrules.conf" ;;
        "Edit User Workspace Rules") open_file "$user/workspacerules.conf" ;;
        "Edit User Settings")        open_file "$user/settings.conf" ;;
        "Edit User Decorations")     open_file "$user/decorations.conf" ;;
        "Edit User Animations")      open_file "$user/animations.conf" ;;
        "Edit User Laptop Settings") open_file "$user/laptops.conf" ;;
    esac
}

menu_system_configs() {
    local choice
    choice=$(printf \
"Edit System Keybinds\nEdit System Startup Apps\nEdit System Window Rules\nEdit System Settings\nEdit System Animations\nEdit System ENV" | \
        gum choose --header "  SYSTEM DEFAULTS")
    [[ -z "$choice" ]] && return
    case "$choice" in
        "Edit System Keybinds")     open_file "$conf/keybinds.conf" ;;
        "Edit System Startup Apps") open_file "$conf/startup.conf" ;;
        "Edit System Window Rules") open_file "$conf/windowrules.conf" ;;
        "Edit System Settings")     open_file "$conf/settings.conf" ;;
        "Edit System Animations")   open_file "$conf/animations.conf" ;;
        "Edit System ENV")          open_file "$conf/env.conf" ;;
    esac
}

menu_utilities() {
    local choice
    choice=$(printf \
"Set SDDM Wallpaper\nChoose Kitty Theme\nConfigure Monitors\nGTK Settings\nQT6 Settings\nQT5 Settings\nChoose Animations\nChoose Monitor Profile\nChoose Rofi Theme\nSearch Keybinds\nToggle Game Mode\nSwitch Dark/Light\nRainbow Borders\nRestore Configs\nSystem Update / Clean" | \
        gum choose --header "  UTILITIES")
    [[ -z "$choice" ]] && return
    case "$choice" in
        "Set SDDM Wallpaper")   bash "$HYPR_SCRIPTS/sddm_wallpaper.sh" --normal ;;
        "Choose Kitty Theme")   bash "$HYPR_SCRIPTS/KittyTheme.sh" ;;
        "Configure Monitors")
            require_cmd nwg-displays && nwg-displays ;;
        "GTK Settings")
            require_cmd nwg-look && nwg-look ;;
        "QT6 Settings")
            require_cmd qt6ct && qt6ct ;;
        "QT5 Settings")
            require_cmd qt5ct && qt5ct ;;
        "Choose Animations")    bash "$HYPR_SCRIPTS/Animations.sh" ;;
        "Choose Monitor Profile") bash "$HYPR_SCRIPTS/MonitorProfiles.sh" ;;
        "Choose Rofi Theme")    bash "$HYPR_SCRIPTS/RofiThemeSelector.sh" ;;
        "Search Keybinds")      bash "$HYPR_SCRIPTS/KeyBinds.sh" ;;
        "Toggle Game Mode")     bash "$HYPR_SCRIPTS/GameMode.sh" ;;
        "Switch Dark/Light")    bash "$HYPR_SCRIPTS/ThemeChanger.sh" ;;
        "Rainbow Borders")      rainbow_borders_menu ;;
        "Restore Configs")      bash "$NECRO_REPO/nd-restore.sh" ;;
        "System Update / Clean") bash "$HYPR_SCRIPTS/nd-update.sh" ;;
    esac
}

# ── MAIN MENU ─────────────────────────────────────────────────────────────────
while true; do
    choice=$(gum choose \
        --header "  NECRODERMIS  //  CONTROL PANEL" \
        "  User Configs" \
        "  System Defaults" \
        "  Wallpaper" \
        "  Hyprlock" \
        "  Monitors" \
        "  Audio" \
        "  Idle / Lock" \
        "  Notifications" \
        "  Utilities" \
        "  Exit" \
    ) || exit 0

    case "$choice" in
        *"User Configs"*)    menu_user_configs ;;
        *"System Defaults"*) menu_system_configs ;;
        *Wallpaper*)         bash "$HOME/.config/hypr/user-scripts/WallpaperSelect.sh" ;;
        *Hyprlock*)          bash "$HYPR_SCRIPTS/hyprlock.sh" ;;
        *Monitors*)          bash "$HYPR_SCRIPTS/MonitorProfiles.sh" ;;
        *Audio*)             bash "$HYPR_SCRIPTS/nd-volume.sh" ;;
        *"Idle / Lock"*)     bash "$HYPR_SCRIPTS/Hypridle.sh" ;;
        *Notifications*)     swaync-client -t ;;
        *Utilities*)         menu_utilities ;;
        *Exit*)              exit 0 ;;
    esac
done
