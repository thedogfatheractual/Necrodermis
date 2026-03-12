#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — SAUTEKH DYNASTY // v0.1.0
# Install Script — Arch / CachyOS / Manjaro / EndeavourOS
# https://github.com/thedogfatheractual/Necrodermis
#
# STASIS DURATION: 60,247,891 YRS  //  47 MAINTENANCE FAULTS UNRESOLVED
# LAST DIAGNOSTIC: 4,891 YEARS AGO  //  TOMB INTEGRITY BREACH DETECTED
# ════════════════════════════════════════════════════════════

# ── DEBUG MODE ──
NECRO_DEBUG=0
for arg in "$@"; do
    [[ "$arg" == "--debug" ]] && NECRO_DEBUG=1
done

# ── GUM BOOTSTRAP ──
if ! command -v gum &>/dev/null; then
    echo "  Acquiring gum (required for installer interface)..."
    if command -v pacman &>/dev/null; then
        command sudo pacman -S --needed --noconfirm gum
    else
        echo "  ERROR: gum not found and pacman unavailable — install gum manually and re-run."
        exit 1
    fi
fi

# ── DEBUG SHIMS ──
if [ "$NECRO_DEBUG" -eq 1 ]; then
    sudo()      { echo -e "  \033[0;33m⚠  [DEBUG] sudo:\033[0m $*"; }
    pacman()    { echo -e "  \033[2;32m   [DEBUG] pacman:\033[0m $*"; }
    systemctl() { echo -e "  \033[2;32m   [DEBUG] systemctl:\033[0m $*"; }
    git()       { echo -e "  \033[2;32m   [DEBUG] git:\033[0m $*"; }
    export -f sudo pacman systemctl git
    necro_aur_debug() { echo -e "  \033[2;32m   [DEBUG] AUR:\033[0m $*"; }
    get_aur_helper() { echo "necro_aur_debug"; }
fi

# ── PATHS ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/necrodermis-backup-$(date +%Y%m%d-%H%M%S)"
WALLPAPER_DIR="$HOME/Pictures/wallpapers/necrodermis"
CONFIG_DIR="$HOME/.config"
NECRO_HOME="$HOME/.local/share/necrodermis"
NECRO_BIN="$HOME/.local/bin"

# ── TUI — source early, dispatch internal flags before anything else loads ──
NECRO_TUI_MODE="standalone"
for arg in "$@"; do
    [[ "$arg" == "--tui-inside" ]] && NECRO_TUI_MODE="inside"
done

if [[ -f "$SCRIPT_DIR/scripts/necro-tui.sh" ]]; then
    source "$SCRIPT_DIR/scripts/necro-tui.sh"
fi

case "${1:-}" in
    --tui-left-pane)     _necro_tui_left_pane;    exit 0 ;;
    --tui-right-pane)    _necro_tui_right_pane;   exit 0 ;;
    --tui-resource-bar)  _necro_tui_resource_bar; exit 0 ;;
esac

# ── TUI — auto-launch tmux if not already inside ──
if [[ "$NECRO_TUI_MODE" == "standalone" ]]; then
    if command -v tmux &>/dev/null; then
        necro_tui_launch "${BASH_SOURCE[0]}" "$@"
        exit 0
    else
        echo ""
        echo -e "  \033[0;33m  tmux not found — running without TUI.\033[0m"
        echo -e "  \033[2;32m  Install tmux for the full Canoptek interface.\033[0m"
        echo ""
    fi
fi

# ── SOURCE ALL MODULES ──
source "$SCRIPT_DIR/scripts/common.sh"
source "$SCRIPT_DIR/scripts/detect.sh"
source "$SCRIPT_DIR/scripts/configure.sh"
source "$SCRIPT_DIR/scripts/icao.sh"
source "$SCRIPT_DIR/installer/components.sh"

for fn in "$SCRIPT_DIR/scripts/functions/"*.sh; do
    source "$fn"
done

# ════════════════════════════════════════════════════════════
# COMPONENT SELECTION
# ════════════════════════════════════════════════════════════

run_selective() {
    print_section "COMPONENT SELECTION  //  DESIGNATE DERMAL LAYERS"
    echo ""
    echo -e "  ${DG}  Existing configurations will be archived before anything is touched.${NC}"
    echo -e "  ${G}  ${BACKUP_DIR}${NC}"
    echo ""
    echo -e "  ${B}  Are there existing configurations on this system you want to preserve?${NC}"
    echo -e "  ${DG}  If yes — deselect those components below. They will not be touched.${NC}"
    echo -e "  ${DG}  If no  — leave everything selected. The full dermal layer will be applied.${NC}"
    echo ""

    local preserve_answer
    if gum confirm --default=false \
        --affirmative="  YES — LET ME CHOOSE  " \
        --negative="  NO — APPLY EVERYTHING  " \
        "  Do you have existing configs you want to keep?"; then
        preserve_answer="y"
    else
        preserve_answer="n"
    fi

    local display_list=()
    declare -A fn_map
    for entry in "${COMPONENTS[@]}"; do
        IFS='|' read -r name category desc fn <<< "$entry"
        local label="${name}  —  ${desc}"
        display_list+=("$label")
        fn_map["$label"]="$fn"
    done

    local selected_components
    if [[ "$preserve_answer" == "y" ]]; then
        echo ""
        echo -e "  ${DG}  SPACE to toggle  //  ENTER to confirm  //  deselect what you want to keep${NC}"
        echo ""
        selected_components=$(printf '%s\n' "${display_list[@]}" | \
            gum choose --no-limit \
                --selected="$(printf '%s,' "${display_list[@]}")" \
                --header="  SELECT COMPONENTS TO INSTALL" \
                --header.foreground="2" \
                --cursor.foreground="2" \
                --selected.foreground="2" \
                --item.foreground="8" \
                --height=22)
    else
        echo ""
        print_info "Full dermal layer scheduled  ${DG}//  all components will be applied${NC}"
        echo ""
        selected_components=$(printf '%s\n' "${display_list[@]}")
    fi

    if [ -z "$selected_components" ]; then
        echo ""
        print_info "No components selected  ${DG}//  the tomb remains undisturbed${NC}"
        return
    fi

    echo ""
    print_section "AWAKENING SEQUENCE  //  INITIATING INSTALLATION"
    echo ""

    for label in "${display_list[@]}"; do
        if echo "$selected_components" | grep -qF "$label"; then
            ${fn_map[$label]}
        else
            IFS='|' read -r name _ <<< "$(printf '%s\n' "${COMPONENTS[@]}" | grep "^${label%%  —*}|")"
            print_skip "${name:-$label}"
        fi
    done
}

# ════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════

print_header

DISTRO="$(detect_distro)"
if [ "$DISTRO" = "unknown" ]; then
    echo -e "  ${R}  WARNING: Unrecognised distribution detected.${NC}"
    echo -e "  ${Y}  This installer targets Arch, CachyOS, and Manjaro only.${NC}"
    echo ""
    confirm "Continue anyway?" || {
        echo -e "\n  ${DG}  Installer aborted. The tomb remains sealed.${NC}\n"
        exit 0
    }
fi

echo -e "  ${DG}  Distribution:${NC} ${G}${B}${DISTRO}${NC}"
echo ""

install_yay
            install_cachyos_repos
necro_init_log

mode=$(gum choose \
    --header="  SELECT INSTALLATION MODE" \
    "Theme only  //  apply Necrodermis to existing Hyprland setup" \
    "Full install  //  packages + configs, standalone Necrodermis")

print_credit

case "$mode" in
    "Full install"*)
        print_section "FULL INSTALLATION MODE  //  COMPLETE AWAKENING SEQUENCE"
        echo ""
        echo -e "${Y}  This will install all packages and deploy Necrodermis configs.${NC}"
        echo -e "${Y}  Estimated time: 10–30 minutes depending on connection.${NC}"
        echo ""
        echo -e "${B}  ── ATTENTION ────────────────────────────────────────────────${NC}"
        echo -e "${Y}  You will be prompted for your sudo password several times.${NC}"
        echo -e "${Y}  Do not leave the terminal unattended during installation.${NC}"
        echo -e "${B}  ─────────────────────────────────────────────────────────────${NC}"
        echo ""
        if confirm "Initiate full awakening sequence?"; then
            configure_timezone
            check_deps
            run_selective
            install_cachyos_repos
        else
            echo -e "\n  ${DG}  The tomb remains sealed. Installer aborted.${NC}\n"
            exit 0
        fi
        ;;
    *)
        print_section "THEME INSTALLATION MODE  //  DERMAL LAYER ONLY"
        necro_init_log
        configure_timezone
        check_deps
        run_selective
        ;;
esac

bundle_uninstaller

necro_post_install_report

necro_tui_done

echo ""
echo -e "  ${DG}  Configuration archive: ${G}${BACKUP_DIR}${NC}"
echo -e "  ${DG}  TO UNINSTALL: ${G}necrodermis-uninstall${NC}"
echo ""
echo -e "  ${DG}  Log out and back in for all changes to take effect.${NC}"
echo ""
echo -e "  ${DG}  The silent king stirs. The stars remember.${NC}"
echo ""
echo -e "${G}${B}  ORGANIC MATTER IS TEMPORARY  //  NECRODERMIS IS ETERNAL${NC}"
echo ""
