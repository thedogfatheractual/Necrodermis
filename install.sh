#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — SAUTEKH DYNASTY // v0.1.0
# Install Script — Arch / CachyOS / Manjaro / EndeavourOS
# https://github.com/thedogfatheractual/Necrodermis
#
# STASIS DURATION: 60,247,891 YRS  //  47 MAINTENANCE FAULTS UNRESOLVED
# LAST DIAGNOSTIC: 4,891 YEARS AGO  //  TOMB INTEGRITY BREACH DETECTED
# ════════════════════════════════════════════════════════════
# Built on JaKooLit's Hyprland-Dots framework
# https://github.com/JaKooLit/Arch-Hyprland
# ════════════════════════════════════════════════════════════

set -e

# ── DEBUG MODE ──
NECRO_DEBUG=0
for arg in "$@"; do
    [[ "$arg" == "--debug" ]] && NECRO_DEBUG=1
done

# ── GUM BOOTSTRAP ──
# Runs before debug shims — uses command builtin to bypass any sudo override
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

# ── TIMEZONE → ICAO LOOKUP TABLE ──
declare -A TZ_ICAO=(
    ["America/Vancouver"]="CYVR:Vancouver"
    ["America/Edmonton"]="CYEG:Edmonton"
    ["America/Calgary"]="CYYC:Calgary"
    ["America/Regina"]="CYQR:Regina"
    ["America/Winnipeg"]="CYWG:Winnipeg"
    ["America/Thunder_Bay"]="CYQT:Thunder Bay"
    ["America/Toronto"]="CYYZ:Toronto"
    ["America/Ottawa"]="CYOW:Ottawa"
    ["America/Montreal"]="CYUL:Montreal"
    ["America/Halifax"]="CYHZ:Halifax"
    ["America/St_Johns"]="CYYT:St. Johns"
    ["America/Anchorage"]="PANC:Anchorage"
    ["America/Juneau"]="PAJN:Juneau"
    ["Pacific/Honolulu"]="PHNL:Honolulu"
    ["America/Los_Angeles"]="KLAX:Los Angeles"
    ["America/Seattle"]="KSEA:Seattle"
    ["America/Las_Vegas"]="KLAS:Las Vegas"
    ["America/Phoenix"]="KPHX:Phoenix"
    ["America/Denver"]="KDEN:Denver"
    ["America/Boise"]="KBOI:Boise"
    ["America/Chicago"]="KORD:Chicago"
    ["America/Dallas"]="KDFW:Dallas"
    ["America/Houston"]="KIAH:Houston"
    ["America/Minneapolis"]="KMSP:Minneapolis"
    ["America/Detroit"]="KDTW:Detroit"
    ["America/New_York"]="KJFK:New York"
    ["America/Boston"]="KBOS:Boston"
    ["America/Philadelphia"]="KPHL:Philadelphia"
    ["America/Washington"]="KDCA:Washington DC"
    ["America/Atlanta"]="KATL:Atlanta"
    ["America/Miami"]="KMIA:Miami"
    ["America/Indianapolis"]="KIND:Indianapolis"
    ["America/St_Louis"]="KSTL:St. Louis"
    ["America/Kansas_City"]="KMCI:Kansas City"
    ["America/Salt_Lake_City"]="KSLC:Salt Lake City"
    ["America/Portland"]="KPDX:Portland"
    ["America/San_Francisco"]="KSFO:San Francisco"
    ["America/San_Diego"]="KSAN:San Diego"
    ["America/Albuquerque"]="KABQ:Albuquerque"
    ["America/New_Orleans"]="KMSY:New Orleans"
    ["America/Nashville"]="KBNA:Nashville"
    ["America/Charlotte"]="KCLT:Charlotte"
    ["America/Orlando"]="KMCO:Orlando"
    ["America/Mexico_City"]="MMMX:Mexico City"
    ["America/Cancun"]="MMUN:Cancun"
    ["America/Guatemala"]="MGGT:Guatemala City"
    ["America/Costa_Rica"]="MROC:San Jose"
    ["America/Bogota"]="SKBO:Bogota"
    ["America/Lima"]="SPIM:Lima"
    ["America/Santiago"]="SCEL:Santiago"
    ["America/Buenos_Aires"]="SAEZ:Buenos Aires"
    ["America/Sao_Paulo"]="SBGR:Sao Paulo"
    ["America/Rio_de_Janeiro"]="SBGL:Rio de Janeiro"
    ["America/Caracas"]="SVMI:Caracas"
    ["Europe/London"]="EGLL:London"
    ["Europe/Dublin"]="EIDW:Dublin"
    ["Europe/Lisbon"]="LPPT:Lisbon"
    ["Europe/Madrid"]="LEMD:Madrid"
    ["Europe/Paris"]="LFPG:Paris"
    ["Europe/Amsterdam"]="EHAM:Amsterdam"
    ["Europe/Brussels"]="EBBR:Brussels"
    ["Europe/Zurich"]="LSZH:Zurich"
    ["Europe/Berlin"]="EDDB:Berlin"
    ["Europe/Frankfurt"]="EDDF:Frankfurt"
    ["Europe/Munich"]="EDDM:Munich"
    ["Europe/Vienna"]="LOWW:Vienna"
    ["Europe/Rome"]="LIRF:Rome"
    ["Europe/Milan"]="LIML:Milan"
    ["Europe/Copenhagen"]="EKCH:Copenhagen"
    ["Europe/Stockholm"]="ESSA:Stockholm"
    ["Europe/Oslo"]="ENGM:Oslo"
    ["Europe/Helsinki"]="EFHK:Helsinki"
    ["Europe/Reykjavik"]="BIRK:Reykjavik"
    ["Europe/Warsaw"]="EPWA:Warsaw"
    ["Europe/Prague"]="LKPR:Prague"
    ["Europe/Budapest"]="LHBP:Budapest"
    ["Europe/Bucharest"]="LROP:Bucharest"
    ["Europe/Athens"]="LGAV:Athens"
    ["Europe/Istanbul"]="LTBA:Istanbul"
    ["Europe/Kiev"]="UKBB:Kyiv"
    ["Europe/Moscow"]="UUEE:Moscow"
    ["Asia/Dubai"]="OMDB:Dubai"
    ["Asia/Riyadh"]="OERK:Riyadh"
    ["Asia/Baghdad"]="ORBI:Baghdad"
    ["Asia/Tehran"]="OIIE:Tehran"
    ["Asia/Jerusalem"]="LLBG:Tel Aviv"
    ["Asia/Qatar"]="OTBD:Doha"
    ["Asia/Karachi"]="OPKC:Karachi"
    ["Asia/Kolkata"]="VABB:Mumbai"
    ["Asia/Dhaka"]="VGHS:Dhaka"
    ["Asia/Colombo"]="VCBI:Colombo"
    ["Asia/Kathmandu"]="VNKT:Kathmandu"
    ["Asia/Bangkok"]="VTBS:Bangkok"
    ["Asia/Ho_Chi_Minh"]="VVTS:Ho Chi Minh City"
    ["Asia/Kuala_Lumpur"]="WMKK:Kuala Lumpur"
    ["Asia/Singapore"]="WSSS:Singapore"
    ["Asia/Jakarta"]="WIII:Jakarta"
    ["Asia/Manila"]="RPLL:Manila"
    ["Asia/Shanghai"]="ZSPD:Shanghai"
    ["Asia/Beijing"]="ZBAA:Beijing"
    ["Asia/Hong_Kong"]="VHHH:Hong Kong"
    ["Asia/Taipei"]="RCTP:Taipei"
    ["Asia/Seoul"]="RKSI:Seoul"
    ["Asia/Tokyo"]="RJTT:Tokyo"
    ["Asia/Osaka"]="RJBB:Osaka"
    ["Australia/Perth"]="YPPH:Perth"
    ["Australia/Darwin"]="YPDN:Darwin"
    ["Australia/Adelaide"]="YPAD:Adelaide"
    ["Australia/Brisbane"]="YBBN:Brisbane"
    ["Australia/Sydney"]="YSSY:Sydney"
    ["Australia/Melbourne"]="YMML:Melbourne"
    ["Pacific/Auckland"]="NZAA:Auckland"
    ["Africa/Cairo"]="HECA:Cairo"
    ["Africa/Lagos"]="DNMM:Lagos"
    ["Africa/Nairobi"]="HKJK:Nairobi"
    ["Africa/Johannesburg"]="FAOR:Johannesburg"
    ["Africa/Cape_Town"]="FACT:Cape Town"
    ["Africa/Casablanca"]="GMMN:Casablanca"
)

# ── SOURCE ALL MODULES ──
source "$SCRIPT_DIR/scripts/common.sh"
source "$SCRIPT_DIR/scripts/detect.sh"
source "$SCRIPT_DIR/scripts/configure.sh"
source "$SCRIPT_DIR/config/components.sh"

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

    # Build ordered display list and function map from COMPONENTS
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

mode=$(gum choose \
    --header="  SELECT INSTALLATION MODE" \
    "Theme only  //  apply Necrodermis to existing Hyprland setup" \
    "Full install  //  complete Arch desktop via JaKooLit, then Necrodermis on top")

print_credit

case "$mode" in
    "Full install"*)
        print_section "FULL INSTALLATION MODE  //  COMPLETE AWAKENING SEQUENCE"
        echo ""
        echo -e "${Y}  This will perform a full desktop installation.${NC}"
        echo -e "${Y}  JaKooLit's installer will run first, followed by Necrodermis.${NC}"
        echo -e "${Y}  Estimated time: 10–30 minutes depending on connection.${NC}"
        echo ""
        if confirm "Initiate full awakening sequence?"; then
            install_yay
            run_jakoolit
            print_section "NECRODERMIS OVERLAY  //  APPLYING DERMAL LAYER"
            configure_timezone
            check_deps
            run_selective
        else
            echo -e "\n  ${DG}  The tomb remains sealed. Installer aborted.${NC}\n"
            exit 0
        fi
        ;;
    *)
        print_section "THEME INSTALLATION MODE  //  DERMAL LAYER ONLY"
        configure_timezone
        check_deps
        run_selective
        ;;
esac

bundle_uninstaller

echo ""
echo -e "${G}${B}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║           NECRODERMIS INSTALLATION COMPLETE                  ║"
echo "  ║           ALL SYSTEMS NOMINAL  //  TOMB WORLD VI ONLINE      ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${DG}  Configuration archive: ${G}${BACKUP_DIR}${NC}"
echo ""
echo -e "  ${DG}  TO UNINSTALL NECRODERMIS:${NC}"
echo -e "  ${G}    necrodermis-uninstall${NC}"
echo ""
echo -e "  ${DG}  Log out and back in for all changes to take effect.${NC}"
echo ""
echo -e "  ${DG}  The silent king stirs. The stars remember.${NC}"
echo ""
echo -e "${G}${B}  ORGANIC MATTER IS TEMPORARY  //  NECRODERMIS IS ETERNAL${NC}"
echo ""
