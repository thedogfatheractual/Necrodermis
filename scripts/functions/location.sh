#!/usr/bin/env bash
# Necrodermis — scripts/functions/location.sh
# Extracted from monolith install-OGSHELL.sh
# Component: configure_location

configure_location() {
    print_section "CANOPTEK ATMOSPHERIC INTERFACE  //  LOCATION CALIBRATION"
    echo ""
    echo -e "${DG}  Location data is used to retrieve METAR weather conditions for${NC}"
    echo -e "${DG}  the SDDM login display. Data is fetched from aviationweather.gov${NC}"
    echo -e "${DG}  at boot only. Nothing is stored or transmitted beyond that request.${NC}"
    echo ""

    local detected
    detected="$(detect_location)"
    local detected_icao=""
    local detected_city=""

    if [ -n "$detected" ]; then
        detected_icao="${detected%%:*}"
        detected_city="${detected##*:}"
        print_ok "System timezone resolved  ${DG}//  nearest station: ${B}${detected_city}${NC} ${DG}(${detected_icao})${NC}"
        echo ""
    fi

    echo -e "  ${G}[1]${NC}  Auto-detect from system timezone${detected_city:+  ${DG}→ ${detected_city} (${detected_icao})${NC}}"
    echo -e "  ${G}[2]${NC}  Detect from IP address  ${DG}//  queries ipinfo.io once, nothing retained${NC}"
    echo -e "  ${G}[3]${NC}  Enter city or airport name manually"
    echo -e "  ${G}[4]${NC}  No weather  ${DG}//  atmospheric sensors offline${NC}"
    echo ""
    echo -en "  ${G}?${NC}  Choice [1/2/3/4]: "
    read -r loc_choice

    case "$loc_choice" in
        4)
            echo ""
            print_info "Atmospheric sensors disabled  //  login display will show: no signal"
            print_info "The tomb is self-contained. No external contact required; that's too much voodoo, and I don't need to see the glowies."
            echo "DISABLED" > /tmp/necrodermis-icao
            ;;
        2)
            echo ""
            echo -ne "  ${DG}Querying ipinfo.io...${NC} "
            local ip_result
            ip_result=$(detect_location_ip)
            if [ -z "$ip_result" ]; then
                echo -e "${R}failed.${NC}"
                print_info "IP geolocation unavailable  //  falling back to manual entry"
                # Recurse into manual path
                loc_choice=3
                # Fall through by re-entering the manual block inline
                echo ""
                echo -e "${DG}  Enter your nearest large city name, or if you know it,${NC}"
                echo -e "${DG}  your airport ICAO code directly (e.g. EGLL for London Heathrow,${NC}"
                echo -e "${DG}  KJFK for New York, YSSY for Sydney).${NC}"
                echo -e "${DG}  Find any ICAO at: https://ourairports.com${NC}"
                echo ""
                echo -en "  ${G}?${NC}  City or ICAO: "
                read -r user_input
                _configure_location_manual "$user_input"
            else
                echo -e "${G}done.${NC}"
                local ip_icao="${ip_result%%:*}"
                local ip_city="${ip_result##*:}"
                echo ""
                print_ok "Nearest station found  ${DG}//  ${B}${ip_city}${NC} ${DG}(${ip_icao})${NC}"
                echo -en "  ${G}?${NC}  Confirm? [Y/n]: "
                read -r confirm_ip
                if [[ ! "$confirm_ip" =~ ^[nN] ]]; then
                    echo "$ip_icao" > /tmp/necrodermis-icao
                    print_ok "Location locked  ${DG}//  ${ip_city} (${ip_icao})${NC}"
                else
                    echo -en "  ${G}?${NC}  Enter ICAO directly: "
                    read -r raw_icao
                    raw_icao=$(echo "$raw_icao" | tr '[:lower:]' '[:upper:]')
                    echo "$raw_icao" > /tmp/necrodermis-icao
                    print_ok "ICAO station set  ${DG}//  ${raw_icao}${NC}"
                fi
            fi
            ;;
        3)
            echo ""
            echo -e "${DG}  Enter your nearest large city name, or if you know it,${NC}"
            echo -e "${DG}  your airport ICAO code directly (e.g. EGLL for London Heathrow,${NC}"
            echo -e "${DG}  KJFK for New York, YSSY for Sydney).${NC}"
            echo -e "${DG}  Find any ICAO at: https://ourairports.com${NC}"
            echo ""
            echo -en "  ${G}?${NC}  City or ICAO: "
            read -r user_input
            _configure_location_manual "$user_input"
            ;;
        *)
            # Option 1 — timezone auto-detect (also catches Enter/invalid input)
            if [ -n "$detected_icao" ]; then
                echo "$detected_icao" > /tmp/necrodermis-icao
                print_ok "Location locked  ${DG}//  ${detected_city} (${detected_icao})${NC}"
            else
                print_info "Timezone resolution failed  //  falling back to manual entry"
                echo ""
                echo -e "${DG}  Enter your nearest large city name, or if you know it,${NC}"
                echo -e "${DG}  your airport ICAO code directly (e.g. EGLL for London Heathrow,${NC}"
                echo -e "${DG}  KJFK for New York, YSSY for Sydney).${NC}"
                echo -e "${DG}  Find any ICAO at: https://ourairports.com${NC}"
                echo ""
                echo -en "  ${G}?${NC}  City or ICAO: "
                read -r user_input
                _configure_location_manual "$user_input"
            fi
            ;;
    esac

    local final_icao
    final_icao=$(cat /tmp/necrodermis-icao 2>/dev/null)
    rm -f /tmp/necrodermis-icao

    # Write ICAO to sitrep config — necro_weather.py and sitrep both read from here
    local SITREP_CONFIG="$HOME/.config/sitrep/config.ini"
    mkdir -p "$HOME/.config/sitrep"

    if [ "$final_icao" = "DISABLED" ] || [ -z "$final_icao" ]; then
        python3 - "$SITREP_CONFIG" "DISABLED" << 'PYEOF'
import sys, configparser
path, icao = sys.argv[1], sys.argv[2]
cfg = configparser.ConfigParser()
cfg.read(path)
if 'Weather' not in cfg: cfg['Weather'] = {}
cfg['Weather']['icao_code'] = icao
with open(path, 'w') as f: cfg.write(f)
PYEOF
        print_info "Atmospheric sensors disabled  //  icao_code = DISABLED"
    else
        python3 - "$SITREP_CONFIG" "$final_icao" << 'PYEOF'
import sys, configparser
path, icao = sys.argv[1], sys.argv[2]
cfg = configparser.ConfigParser()
cfg.read(path)
if 'Weather' not in cfg: cfg['Weather'] = {}
cfg['Weather']['icao_code'] = icao
with open(path, 'w') as f: cfg.write(f)
PYEOF
        print_ok "Location written  ${DG}//  icao_code = ${final_icao}${NC}"
        print_info "Running initial atmospheric scan..."
        python3 "$HOME/.local/share/necrodermis/necro_weather.py" 2>/dev/null \
            && print_ok "Atmospheric data acquired  ${DG}//  sensors online${NC}" \
            || print_info "Initial scan failed  //  will retry at next boot"
    fi
}
