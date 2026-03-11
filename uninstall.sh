#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — SAUTEKH DYNASTY
# Uninstall Script — Arch / CachyOS / Manjaro / EndeavourOS
# https://github.com/thedogfatheractual/Necrodermis
#
# ════════════════════════════════════════════════════════════
#
#  This script removes the Necrodermis theme from your system.
#
#  It will ask you what to remove, one component at a time.
#  Nothing is deleted without your confirmation.
#  Where possible, your previous configs will be restored
#  from the backup taken during installation.
#
#  To run this, open a terminal and type:
#    necrodermis-uninstall
#
#  Or run it directly:
#    ~/.local/share/necrodermis/uninstall.sh
#
# ════════════════════════════════════════════════════════════

set -e

# ── COLOURS ──
G='\033[0;32m'
DG='\033[2;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[1m'
NC='\033[0m'

# ── PATHS ──
CONFIG_DIR="$HOME/.config"
WALLPAPER_DIR="$HOME/Pictures/wallpapers/necrodermis"
NECRO_HOME="$HOME/.local/share/necrodermis"
NECRO_BIN="$HOME/.local/bin"

# ════════════════════════════════════════════════════════════
# HELPERS
# ════════════════════════════════════════════════════════════

print_header() {
    clear
    echo ""
    echo -e "${G}${B}"
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                  ║"
    echo "  ║          ███╗   ██╗███████╗ ██████╗██████╗  ██████╗             ║"
    echo "  ║          ████╗  ██║██╔════╝██╔════╝██╔══██╗██╔═══██╗            ║"
    echo "  ║          ██╔██╗ ██║█████╗  ██║     ██████╔╝██║   ██║            ║"
    echo "  ║          ██║╚██╗██║██╔══╝  ██║     ██╔══██╗██║   ██║            ║"
    echo "  ║          ██║ ╚████║███████╗╚██████╗██║  ██║╚██████╔╝            ║"
    echo "  ║          ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝            ║"
    echo "  ║                                                                  ║"
    echo "  ║              DEACTIVATION PROTOCOL  //  TOMBWORLD VI             ║"
    echo "  ║                    RETURNING TO STASIS                          ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DG}  THE SILENT KING COMMANDS WITHDRAWAL${NC}"
    echo -e "${DG}  CANOPTEK SCARABS: RETRIEVING COMPONENTS${NC}"
    echo -e "${DG}  RESURRECTION PROTOCOLS: SUSPENDED${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${G}${B}  ╔─────────────────────────────────────────────────────────────╗${NC}"
    echo -e "${G}${B}  ║  $1${NC}"
    echo -e "${G}${B}  ╚─────────────────────────────────────────────────────────────╝${NC}"
}

print_ok()   { echo -e "  ${G}✓${NC}  $1"; }
print_skip() { echo -e "  ${Y}·${NC}  $1 ${DG}[not found — skipped]${NC}"; }
print_err()  { echo -e "  ${R}✗${NC}  $1"; }
print_info() { echo -e "  ${DG}   $1${NC}"; }

ask() {
    echo -en "\n  ${G}?${NC}  Remove ${B}$1${NC}? [Y/n] "
    read -r answer
    [[ ! "$answer" =~ ^[nN] ]]
}

confirm() {
    echo -en "  ${G}?${NC}  $1 [Y/n] "
    read -r answer
    [[ ! "$answer" =~ ^[nN] ]]
}

restore_or_remove() {
    local dst="$1"
    local label="$2"
    local backup_found=0

    local latest_backup
    latest_backup=$(ls -dt "$HOME"/.config/necrodermis-backup-* 2>/dev/null | head -1)

    if [ -n "$latest_backup" ] && [ -e "$latest_backup/$(basename "$dst")" ]; then
        cp -r "$latest_backup/$(basename "$dst")" "$dst"
        print_ok "$label  ${DG}//  previous configuration restored${NC}"
        backup_found=1
    fi

    if [ "$backup_found" -eq 0 ]; then
        if [ -e "$dst" ]; then
            rm -rf "$dst"
            print_ok "$label  ${DG}//  component purged${NC}"
        else
            print_skip "$label"
        fi
    fi
}

safe_remove() {
    local path="$1"
    local label="$2"
    if [ -e "$path" ]; then
        rm -rf "$path"
        print_ok "$label  ${DG}//  purged${NC}"
    else
        print_skip "$label"
    fi
}

sudo_remove() {
    local path="$1"
    local label="$2"
    if [ -e "$path" ]; then
        sudo rm -rf "$path"
        print_ok "$label  ${DG}//  purged${NC}"
    else
        print_skip "$label"
    fi
}

# ════════════════════════════════════════════════════════════
# COMPONENT REMOVERS
# ════════════════════════════════════════════════════════════

remove_gtk() {
    print_section "GTK THEME  //  STRIPPING DERMAL LAYER"
    sudo_remove "/usr/share/themes/Necrodermis-green-Dark-compact" "GTK theme files"
    restore_or_remove "$CONFIG_DIR/gtk-3.0/gtk.css" "GTK3 user CSS"
    restore_or_remove "$CONFIG_DIR/gtk-4.0/gtk.css" "GTK4 user CSS"
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    print_info "GTK theme reset to Adwaita"
}

remove_icons() {
    print_section "ICON THEME  //  PURGING VISUAL RECOGNITION MATRIX"
    sudo_remove "/usr/share/icons/Flat-Remix-Necrodermis" "icon theme files"
    gsettings set org.gnome.desktop.interface icon-theme 'hicolor' 2>/dev/null || true
    print_info "Icon theme reset to hicolor"
}

remove_wallpapers() {
    print_section "WALLPAPERS  //  PURGING TOMB WORLD SURFACE RENDERS"
    safe_remove "$WALLPAPER_DIR" "necrodermis wallpaper directory"
    print_info "Personal wallpapers in ~/Pictures/wallpapers/ are untouched"
}

remove_hypr() {
    print_section "HYPRLAND CONFIGS  //  PURGING ENVIRONMENTAL CONTROL MATRIX"
    restore_or_remove "$CONFIG_DIR/hypr/UserConfigs/UserKeybinds.conf" "UserKeybinds.conf"
    restore_or_remove "$CONFIG_DIR/hypr/UserConfigs/UserDecorations.conf" "UserDecorations.conf"
    restore_or_remove "$CONFIG_DIR/hypr/UserConfigs/01-UserDefaults.conf" "01-UserDefaults.conf"
}

remove_waybar() {
    print_section "WAYBAR  //  DEACTIVATING STATUS ARRAY"
    restore_or_remove "$CONFIG_DIR/waybar/config" "waybar config"
    restore_or_remove "$CONFIG_DIR/waybar/style.css" "waybar style"
}

remove_rofi() {
    print_section "ROFI  //  PURGING COMMAND INTERFACE OVERLAY"
    restore_or_remove "$CONFIG_DIR/rofi/config.rasi" "rofi config"
    safe_remove "$CONFIG_DIR/rofi/necrodermis.rasi" "necrodermis rofi theme"
}

remove_kitty() {
    print_section "KITTY  //  PURGING TERMINAL NODE"
    restore_or_remove "$CONFIG_DIR/kitty/kitty.conf" "kitty.conf"
}

remove_qt() {
    print_section "QT6 / KVANTUM  //  STRIPPING SECONDARY DERMAL LAYER"
    safe_remove "$CONFIG_DIR/Kvantum/necrodermis.kvconfig" "Kvantum theme"
    restore_or_remove "$CONFIG_DIR/qt6ct/qt6ct.conf" "qt6ct config"
}

remove_btop() {
    print_section "BTOP  //  DEACTIVATING CANOPTEK PROCESS MONITOR"
    restore_or_remove "$CONFIG_DIR/btop/btop.conf" "btop config"
    safe_remove "$CONFIG_DIR/btop/themes/necrodermis.theme" "necrodermis btop theme"
}

remove_cava() {
    print_section "CAVA  //  SILENCING ACOUSTIC RESONANCE DISPLAY"
    restore_or_remove "$CONFIG_DIR/cava/config" "cava config"
}

remove_fastfetch() {
    print_section "FASTFETCH  //  PURGING SYSTEM MANIFEST"
    restore_or_remove "$CONFIG_DIR/fastfetch/config.jsonc" "fastfetch config"
    safe_remove "$CONFIG_DIR/fastfetch/necron-warrior-final.txt" "necron warrior sigil"
}

remove_fish() {
    print_section "FISH  //  PURGING SHELL INTERFACE"
    restore_or_remove "$CONFIG_DIR/fish/config.fish" "config.fish"
}

remove_swaync() {
    print_section "SWAYNC  //  DEACTIVATING COMMUNICATION ARRAY"
    restore_or_remove "$CONFIG_DIR/swaync/config.json" "swaync config"
    restore_or_remove "$CONFIG_DIR/swaync/style.css" "swaync style"
    swaync-client --reload-config 2>/dev/null || true
}

remove_sddm() {
    print_section "SDDM  //  SEALING TOMB WORLD AWAKENING INTERFACE"
    sudo systemctl disable necrodermis-weather.service 2>/dev/null || true
    sudo systemctl stop necrodermis-weather.service 2>/dev/null || true
    sudo_remove "/etc/systemd/system/necrodermis-weather.service" "weather service"
    sudo_remove "/etc/systemd/system/sddm.service.d/necrodermis.conf" "SDDM QML override"
    sudo_remove "/etc/sddm.conf.d/necrodermis.conf" "SDDM theme config"
    sudo_remove "/usr/share/sddm/themes/sddm-astronaut-theme/Main.qml" "Main.qml"
    sudo_remove "/usr/share/sddm/themes/sddm-astronaut-theme/Components/Clock.qml" "Clock.qml"
    sudo_remove "/usr/share/sddm/themes/sddm-astronaut-theme/Components/LoginForm.qml" "LoginForm.qml"
    sudo_remove "/usr/share/sddm/themes/sddm-astronaut-theme/theme.conf" "theme.conf"
    sudo_remove "/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/necrodermis.jpg" "background image"
    sudo_remove "/usr/share/sddm/themes/sddm-astronaut-theme/weather.sh" "weather script"
    rm -f /tmp/sddm-weather /tmp/sddm-weather-code /tmp/sddm-weather-moon
    sudo systemctl daemon-reload
    print_ok "Tomb world interface sealed  ${DG}//  SDDM restored to default${NC}"
}

remove_jakoolit() {
    print_section "JAKOOLIT HYPRLAND-DOTS  //  STRUCTURAL FRAMEWORK REMOVAL"
    echo ""
    echo -e "${Y}  This will remove JaKooLit's Hyprland-Dots and Hyprland itself.${NC}"
    echo -e "${Y}  Any other window manager (Sway etc.) will be unaffected.${NC}"
    echo ""

    if confirm "Remove Hyprland config directory (~/.config/hypr)?"; then
        safe_remove "$CONFIG_DIR/hypr" "Hyprland config directory"
    fi

    if confirm "Remove Hyprland and related packages via pacman?"; then
        local HYPR_PKGS=(
            hyprland uwsm hypridle hyprlock
            xdg-desktop-portal-hyprland
            swww waybar swaync rofi-wayland
            wlogout slurp swappy
        )
        local installed=()
        for pkg in "${HYPR_PKGS[@]}"; do
            pacman -Qi "$pkg" &>/dev/null && installed+=("$pkg")
        done
        if [ ${#installed[@]} -gt 0 ]; then
            print_info "Removing: ${installed[*]}"
            sudo pacman -Rns "${installed[@]}" --noconfirm
            print_ok "Hyprland packages removed  ${DG}//  framework purged${NC}"
        else
            print_skip "No Hyprland packages found"
        fi
    fi

    if confirm "Remove JaKooLit source directory (~/Arch-Hyprland)?"; then
        safe_remove "$HOME/Arch-Hyprland" "JaKooLit source directory"
    fi
}

remove_necrodermis_home() {
    print_section "NECRODERMIS FILES  //  PURGING LOCAL INSTALLATION"
    safe_remove "$NECRO_BIN/necrodermis-uninstall" "necrodermis-uninstall command"

    # Remove PATH entries we added
    for rc in "$CONFIG_DIR/fish/config.fish" "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ] && grep -q "# Necrodermis" "$rc"; then
            sed -i '/# Necrodermis/,+1d' "$rc"
            print_info "Removed PATH entry from $(basename "$rc")"
        fi
    done

    # Ask last — this removes the script that's currently running
    if confirm "Remove Necrodermis installation files (~/.local/share/necrodermis/)?"; then
        echo ""
        print_info "Scheduling removal of installation directory..."
        # Use a subshell trap so the dir is removed after this script exits
        trap "rm -rf '$NECRO_HOME'" EXIT
        print_ok "Necrodermis home  ${DG}//  will be purged on exit${NC}"
    fi
}

remove_backups() {
    print_section "BACKUP ARCHIVES  //  PURGING STORED CONFIGURATIONS"
    local backups
    backups=$(ls -d "$HOME"/.config/necrodermis-backup-* 2>/dev/null || true)
    if [ -n "$backups" ]; then
        echo "$backups" | while read -r b; do
            print_info "Found: $b"
        done
        echo ""
        if confirm "Delete all Necrodermis backup archives?"; then
            echo "$backups" | while read -r b; do
                rm -rf "$b"
                print_ok "$(basename "$b")  ${DG}//  purged${NC}"
            done
        fi
    else
        print_skip "No backup archives found"
    fi
}

remove_grub() {
    print_section "GRUB  //  PURGING BOOT SEQUENCE OVERRIDE"
    sudo_remove "/boot/grub/themes/necrodermis" "GRUB theme directory"

    if [ -f /etc/default/grub.necrodermis-backup ]; then
        sudo cp /etc/default/grub.necrodermis-backup /etc/default/grub
        sudo rm -f /etc/default/grub.necrodermis-backup
        print_ok "Boot defaults restored  ${DG}//  from necrodermis-backup${NC}"
    elif grep -q "sautekh" /etc/default/grub 2>/dev/null; then
        sudo sed -i '/^GRUB_THEME=.*sautekh/d' /etc/default/grub
        print_ok "GRUB_THEME entry removed  ${DG}//  /etc/default/grub${NC}"
    else
        print_skip "GRUB_THEME entry  (not found in /etc/default/grub)"
    fi

    print_info "Regenerating boot configuration  //  stand by..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    print_ok "Boot configuration updated  ${DG}//  default theme restored${NC}"
}

remove_plymouth() {
    print_section "PLYMOUTH  //  PURGING INITRAMFS SPLASH PROTOCOL"

    if command -v plymouth-set-default-theme &>/dev/null; then
        # bgrt is the standard firmware logo fallback; text is the safe fallback
        sudo plymouth-set-default-theme bgrt 2>/dev/null \
            || sudo plymouth-set-default-theme text 2>/dev/null \
            || true
        print_ok "Plymouth theme reset  ${DG}//  default restored${NC}"
    fi

    sudo_remove "/usr/share/plymouth/themes/necrodermis" "Plymouth theme directory"

    print_info "Rebuilding initramfs  //  this will take a moment..."
    sudo mkinitcpio -P
    print_ok "Initramfs rebuilt  ${DG}//  splash protocol cleared${NC}"
}

# ════════════════════════════════════════════════════════════
# SELECTIVE UNINSTALL
# ════════════════════════════════════════════════════════════

run_selective() {
    echo ""
    echo -e "${DG}  Where available, previous configurations will be restored${NC}"
    echo -e "${DG}  from the most recent Necrodermis backup archive.${NC}"
    echo -e "${DG}  Components with no backup will be removed entirely.${NC}"

    ask "Hyprland configs  ${DG}(keybinds, decorations, defaults)${NC}" \
        && remove_hypr      || print_skip "Hyprland configs"
    ask "Waybar" \
        && remove_waybar    || print_skip "Waybar"
    ask "Rofi" \
        && remove_rofi      || print_skip "Rofi"
    ask "Kitty" \
        && remove_kitty     || print_skip "Kitty"
    ask "GTK3/4 theme" \
        && remove_gtk       || print_skip "GTK theme"
    ask "Qt6 / Kvantum" \
        && remove_qt        || print_skip "Qt6/Kvantum"
    ask "Btop" \
        && remove_btop      || print_skip "Btop"
    ask "Cava" \
        && remove_cava      || print_skip "Cava"
    ask "Fastfetch" \
        && remove_fastfetch || print_skip "Fastfetch"
    ask "Fish prompt" \
        && remove_fish      || print_skip "Fish"
    ask "Swaync" \
        && remove_swaync    || print_skip "Swaync"
    ask "SDDM login theme" \
        && remove_sddm      || print_skip "SDDM"
    ask "Icons  ${DG}(Flat-Remix-Necrodermis)${NC}" \
        && remove_icons     || print_skip "Icons"
    ask "Wallpapers  ${DG}(~/Pictures/wallpapers/necrodermis/)${NC}" \
        && remove_wallpapers || print_skip "Wallpapers"
    ask "GRUB theme  ${DG}(boot sequence override — requires sudo + reboot)${NC}" \
        && remove_grub      || print_skip "GRUB theme"
    ask "Plymouth  ${DG}(initramfs splash — requires sudo + reboot)${NC}" \
        && remove_plymouth  || print_skip "Plymouth"
    ask "Backup archives  ${DG}(~/.config/necrodermis-backup-*)${NC}" \
        && remove_backups   || print_skip "Backup archives"
    ask "Necrodermis installation files  ${DG}(~/.local/share/necrodermis/)${NC}" \
        && remove_necrodermis_home || print_skip "Necrodermis home"
}

# ════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════

print_header

echo -e "${Y}  This will remove Necrodermis theme components from your system.${NC}"
echo -e "${Y}  Previous configurations will be restored from backup where available.${NC}"
echo -e "${Y}  Components with no backup will be permanently deleted.${NC}"
echo ""
echo -e "  ${G}${B}Select uninstall mode:${NC}"
echo ""
echo -e "  ${G}  [1]${NC}  ${B}Theme only${NC}   ${DG}//  remove Necrodermis skin, leave Hyprland intact${NC}"
echo -e "  ${G}  [2]${NC}  ${B}Full removal${NC} ${DG}//  remove everything including JaKooLit and Hyprland${NC}"
echo ""
echo -en "  ${G}?${NC}  Choice [1/2]: "
read -r mode

echo ""
if ! confirm "Initiate deactivation protocol?"; then
    echo -e "\n  ${DG}  Deactivation aborted. The tomb endures.${NC}\n"
    exit 0
fi

case "$mode" in
    2)
        print_section "FULL REMOVAL MODE  //  COMPLETE DEACTIVATION SEQUENCE"
        echo ""
        echo -e "${R}  This removes Necrodermis, JaKooLit's dots, and Hyprland.${NC}"
        echo -e "${R}  This cannot be undone beyond what backups exist.${NC}"
        echo ""
        if confirm "Confirm full removal — absolutely certain?"; then
            run_selective
            remove_jakoolit
        else
            echo -e "\n  ${DG}  Full removal aborted. Running theme-only removal instead.${NC}"
            run_selective
        fi
        ;;
    *)
        print_section "THEME REMOVAL MODE  //  DERMAL LAYER ONLY"
        run_selective
        ;;
esac

# ── COMPLETION ──
echo ""
echo -e "${G}${B}"
echo "  ╔══════════════════════════════════════════════════════════════════╗"
echo "  ║                                                                  ║"
echo "  ║           NECRODERMIS DEACTIVATION COMPLETE                      ║"
echo "  ║           THE DYNASTY RETURNS TO STASIS                          ║"
echo "  ║           WE SHALL RISE AGAIN WHEN THE STARS ARE RIGHT           ║"
echo "  ║                                                                  ║"
echo "  ╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${DG}  Log out and back in for all changes to take effect.${NC}"
echo ""
echo -e "${DG}  The silent king sleeps. The stars forget.${NC}"
echo -e "${DG}  But the necrodermis endures.${NC}"
echo ""
echo -e "${G}${B}  ORGANIC MATTER IS TEMPORARY  //  NECRODERMIS IS ETERNAL${NC}"
echo ""
