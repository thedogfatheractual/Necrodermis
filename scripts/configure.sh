#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — CONFIGURATION STEPS
# Sourced by install.sh — do not run directly
# ════════════════════════════════════════════════════════════

configure_timezone() {
    print_section "CHRONOMETRIC CALIBRATION  //  SYSTEM CLOCK ALIGNMENT"

    local current_tz
    current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null \
                 || cat /etc/timezone 2>/dev/null \
                 || echo "Unknown")
    local ntp_status
    ntp_status=$(timedatectl show --property=NTP --value 2>/dev/null || echo "inactive")

    echo ""
    print_info "Current timezone  ${DG}//  ${B}${current_tz}${NC}"
    print_info "Network time sync ${DG}//  ${B}${ntp_status}${NC}"
    echo ""

    if ask "Synchronise system clock with network time"; then
        necro_run sudo timedatectl set-ntp true
        print_ok "NTP sync enabled  ${DG}//  chronometric drift corrected${NC}"
    else
        print_skip "NTP sync"
    fi

    echo ""
    if gum confirm --default=true "  Keep current timezone: ${current_tz}?"; then
        print_ok "Timezone confirmed  ${DG}//  ${B}${current_tz}${NC}"
    else
        echo ""
        print_info "Format: Region/City  ${DG}//  e.g. America/Winnipeg, Europe/London${NC}"
        print_info "Reference: timedatectl list-timezones"
        echo ""
        local new_tz
        new_tz=$(gum input \
            --placeholder "Region/City (e.g. America/Winnipeg)" \
            --prompt "  → ")
        if timedatectl list-timezones 2>/dev/null | grep -qx "$new_tz"; then
            necro_run sudo timedatectl set-timezone "$new_tz"
            print_ok "Timezone locked  ${DG}//  ${B}${new_tz}${NC}"
        else
            print_err "Unrecognised timezone: ${new_tz}  ${DG}//  keeping current${NC}"
        fi
    fi
}

_configure_location_manual() {
    local user_input="$1"
    local raw matched_icao="" matched_city="" input_lower key entry city city_lower raw_icao

    if [[ "$user_input" =~ ^[A-Za-z]{3,4}$ ]]; then
        raw=$(echo "$user_input" | tr '[:lower:]' '[:upper:]')
        echo "$raw" > /tmp/necrodermis-icao
        print_ok "ICAO station set  ${DG}//  ${raw}${NC}"
        return
    fi

    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    for key in "${!TZ_ICAO[@]}"; do
        entry="${TZ_ICAO[$key]}"
        city="${entry##*:}"
        city_lower=$(echo "$city" | tr '[:upper:]' '[:lower:]')
        if [[ "$city_lower" == *"$input_lower"* ]]; then
            matched_icao="${entry%%:*}"
            matched_city="$city"
            break
        fi
    done

    if [ -n "$matched_icao" ]; then
        echo ""
        print_ok "Match found  ${DG}//  ${B}${matched_city}${NC} ${DG}→ ${matched_icao}${NC}"
        if gum confirm --default=true "  Confirm ${matched_city} (${matched_icao})?"; then
            echo "$matched_icao" > /tmp/necrodermis-icao
            print_ok "Location locked  ${DG}//  ${matched_city} (${matched_icao})${NC}"
        else
            raw_icao=$(gum input \
                --placeholder "ICAO code (e.g. CYWG)" \
                --prompt "  → ")
            raw_icao=$(echo "$raw_icao" | tr '[:lower:]' '[:upper:]')
            echo "$raw_icao" > /tmp/necrodermis-icao
            print_ok "ICAO station set  ${DG}//  ${raw_icao}${NC}"
        fi
    else
        echo ""
        print_info "No match found for '${user_input}'"
        print_info "Find your ICAO at: https://ourairports.com"
        echo ""
        raw_icao=$(gum input \
            --placeholder "ICAO code, or leave blank to disable weather" \
            --prompt "  → ")
        if [ -z "$raw_icao" ]; then
            echo "DISABLED" > /tmp/necrodermis-icao
            print_info "Atmospheric sensors offline"
        else
            raw_icao=$(echo "$raw_icao" | tr '[:lower:]' '[:upper:]')
            echo "$raw_icao" > /tmp/necrodermis-icao
            print_ok "ICAO station set  ${DG}//  ${raw_icao}${NC}"
        fi
    fi
}

configure_location() {
    print_section "CANOPTEK ATMOSPHERIC INTERFACE  //  LOCATION CALIBRATION"
    echo ""
    echo -e "${DG}  Location data is used to retrieve METAR weather conditions for${NC}"
    echo -e "${DG}  the SDDM login display. Fetched from aviationweather.gov at boot only.${NC}"
    echo ""

    local detected
    detected="$(detect_location)"
    local detected_icao="" detected_city=""
    if [ -n "$detected" ]; then
        detected_icao="${detected%%:*}"
        detected_city="${detected##*:}"
        print_ok "System timezone resolved  ${DG}//  nearest station: ${B}${detected_city}${NC} ${DG}(${detected_icao})${NC}"
        echo ""
    fi

    local opt_tz="Auto-detect from system timezone${detected_city:+ → ${detected_city} (${detected_icao})}"
    local opt_ip="Detect from IP address  //  queries ipinfo.io once, nothing retained"
    local opt_manual="Enter city or airport name manually"
    local opt_off="No weather  //  atmospheric sensors offline"

    echo ""
    local loc_choice
    loc_choice=$(gum choose \
        --header="  LOCATION SOURCE" \
        "$opt_tz" "$opt_ip" "$opt_manual" "$opt_off")

    case "$loc_choice" in
        "$opt_off"*)
            echo ""
            print_info "Atmospheric sensors disabled  //  login display will show: no signal"
            print_info "The tomb is self-contained. No external contact required; that's too much voodoo"
            echo "DISABLED" > /tmp/necrodermis-icao
            ;;
        "$opt_ip"*)
            echo ""
            echo -ne "  ${DG}Querying ipinfo.io...${NC} "
            local ip_result
            ip_result=$(detect_location_ip)
            if [ -z "$ip_result" ]; then
                echo -e "${R}failed.${NC}"
                print_info "IP geolocation unavailable  //  falling back to manual entry"
                echo ""
                local user_input
                user_input=$(gum input \
                    --placeholder "City or ICAO (e.g. CYWG, London, New York)" \
                    --prompt "  → ")
                _configure_location_manual "$user_input"
            else
                echo -e "${G}done.${NC}"
                local ip_icao="${ip_result%%:*}"
                local ip_city="${ip_result##*:}"
                echo ""
                print_ok "Nearest station found  ${DG}//  ${B}${ip_city}${NC} ${DG}(${ip_icao})${NC}"
                if gum confirm --default=true "  Confirm ${ip_city} (${ip_icao})?"; then
                    echo "$ip_icao" > /tmp/necrodermis-icao
                    print_ok "Location locked  ${DG}//  ${ip_city} (${ip_icao})${NC}"
                else
                    local raw_icao
                    raw_icao=$(gum input --placeholder "ICAO code (e.g. CYWG)" --prompt "  → ")
                    raw_icao=$(echo "$raw_icao" | tr '[:lower:]' '[:upper:]')
                    echo "$raw_icao" > /tmp/necrodermis-icao
                    print_ok "ICAO station set  ${DG}//  ${raw_icao}${NC}"
                fi
            fi
            ;;
        "$opt_manual"*)
            echo ""
            print_info "Enter your nearest large city name, or ICAO code directly"
            print_info "Examples: EGLL (London Heathrow), KJFK (New York), YSSY (Sydney)"
            print_info "Find any ICAO at: https://ourairports.com"
            echo ""
            local user_input
            user_input=$(gum input \
                --placeholder "City or ICAO (e.g. CYWG, London, New York)" \
                --prompt "  → ")
            _configure_location_manual "$user_input"
            ;;
        *)
            if [ -n "$detected_icao" ]; then
                echo "$detected_icao" > /tmp/necrodermis-icao
                print_ok "Location locked  ${DG}//  ${detected_city} (${detected_icao})${NC}"
            else
                print_info "Timezone resolution failed  //  falling back to manual entry"
                echo ""
                local user_input
                user_input=$(gum input \
                    --placeholder "City or ICAO (e.g. CYWG, London, New York)" \
                    --prompt "  → ")
                _configure_location_manual "$user_input"
            fi
            ;;
    esac

    local final_icao
    final_icao=$(cat /tmp/necrodermis-icao 2>/dev/null)
    rm -f /tmp/necrodermis-icao

    local SITREP_CONFIG="$HOME/.config/sitrep/config.ini"
    mkdir -p "$HOME/.config/sitrep"

    python3 - "$SITREP_CONFIG" "${final_icao:-DISABLED}" << 'PYEOF'
import sys, configparser
path, icao = sys.argv[1], sys.argv[2]
cfg = configparser.ConfigParser()
cfg.read(path)
if 'Weather' not in cfg: cfg['Weather'] = {}
cfg['Weather']['icao_code'] = icao
with open(path, 'w') as f: cfg.write(f)
PYEOF

    if [ "${final_icao:-DISABLED}" = "DISABLED" ] || [ -z "$final_icao" ]; then
        print_info "Atmospheric sensors disabled  //  icao_code = DISABLED"
    else
        print_ok "Location written  ${DG}//  icao_code = ${final_icao}${NC}"
        print_info "Running initial atmospheric scan..."
        python3 "$HOME/.local/share/necrodermis/necro_weather.py" 2>/dev/null \
            && print_ok "Atmospheric data acquired  ${DG}//  sensors online${NC}" \
            || print_info "Initial scan failed  //  will retry at next boot"
    fi
}

install_yay() {
    print_section "YAY  //  AUR HELPER ACQUISITION"
    if command -v yay &>/dev/null; then
        print_ok "yay already present  ${DG}//  skipping${NC}"; return
    fi
    if command -v paru &>/dev/null; then
        print_ok "paru detected  ${DG}//  AUR helper already available${NC}"; return
    fi
    print_info "No AUR helper found  //  deploying yay..."
    command -v git &>/dev/null || sudo pacman -S git --noconfirm
    sudo pacman -S --needed base-devel --noconfirm
    local tmp_dir; tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    cd "$tmp_dir/yay" && makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$tmp_dir"
    print_ok "yay installed  ${DG}//  AUR access online${NC}"
}

check_deps() {
    print_section "CANOPTEK DEPENDENCY SCAN  //  VERIFYING SYSTEM INTEGRITY"
    local AUR_HELPER; AUR_HELPER="$(get_aur_helper)"
    local PACMAN_DEPS=(
        hyprland uwsm waybar swaync swww hypridle sddm
        kitty thunar thunar-volman thunar-archive-plugin
        tumbler ffmpegthumbnailer gvfs
        rofi-wayland kvantum qt6ct
        btop cava fastfetch fish
        jq curl python gum
        cliphist wl-clipboard
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        network-manager-applet blueman brightnessctl
        playerctl pamixer pavucontrol
        wlogout slurp swappy
    )
    local missing=()
    for pkg in "${PACMAN_DEPS[@]}"; do
        pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        print_info "Missing nodes detected: ${missing[*]}"
        echo ""
        if confirm "Dispatch canoptek scarabs to acquire missing packages?"; then
            sudo pacman -S --needed "${missing[@]}"
        else
            echo -e "\n  ${Y}  Warning: missing components may cause instability.${NC}"
        fi
    else
        print_ok "All system nodes accounted for  ${DG}//  integrity nominal${NC}"
    fi
    if ! pacman -Qi "wallust-git" &>/dev/null 2>&1 && [ -n "$AUR_HELPER" ]; then
        if confirm "Install wallust-git from AUR (dynamic colour extraction)?"; then
            $AUR_HELPER -S --needed wallust-git
        fi
    fi
}
