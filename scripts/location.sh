#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — CANOPTEK ATMOSPHERIC INTERFACE
# Timezone → ICAO lookup table
# Source: aviationweather.gov METAR feed
# ════════════════════════════════════════════════════════════

# Format: ["Timezone"]="ICAO:City Name"
declare -A TZ_ICAO=(
    # ── CANADA ──
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

    # ── UNITED STATES ──
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

    # ── MEXICO / CENTRAL AMERICA ──
    ["America/Mexico_City"]="MMMX:Mexico City"
    ["America/Cancun"]="MMUN:Cancun"
    ["America/Guatemala"]="MGGT:Guatemala City"
    ["America/Costa_Rica"]="MROC:San Jose"

    # ── SOUTH AMERICA ──
    ["America/Bogota"]="SKBO:Bogota"
    ["America/Lima"]="SPIM:Lima"
    ["America/Santiago"]="SCEL:Santiago"
    ["America/Buenos_Aires"]="SAEZ:Buenos Aires"
    ["America/Sao_Paulo"]="SBGR:Sao Paulo"
    ["America/Rio_de_Janeiro"]="SBGL:Rio de Janeiro"
    ["America/Caracas"]="SVMI:Caracas"

    # ── UK / IRELAND ──
    ["Europe/London"]="EGLL:London"
    ["Europe/Dublin"]="EIDW:Dublin"

    # ── WESTERN EUROPE ──
    ["Europe/Lisbon"]="LPPT:Lisbon"
    ["Europe/Madrid"]="LEMD:Madrid"
    ["Europe/Paris"]="LFPG:Paris"
    ["Europe/Amsterdam"]="EHAM:Amsterdam"
    ["Europe/Brussels"]="EBBR:Brussels"
    ["Europe/Luxembourg"]="ELLX:Luxembourg"
    ["Europe/Zurich"]="LSZH:Zurich"
    ["Europe/Geneva"]="LSGG:Geneva"
    ["Europe/Berlin"]="EDDB:Berlin"
    ["Europe/Frankfurt"]="EDDF:Frankfurt"
    ["Europe/Hamburg"]="EDDH:Hamburg"
    ["Europe/Munich"]="EDDM:Munich"
    ["Europe/Vienna"]="LOWW:Vienna"
    ["Europe/Rome"]="LIRF:Rome"
    ["Europe/Milan"]="LIML:Milan"
    ["Europe/Copenhagen"]="EKCH:Copenhagen"
    ["Europe/Stockholm"]="ESSA:Stockholm"
    ["Europe/Oslo"]="ENGM:Oslo"
    ["Europe/Helsinki"]="EFHK:Helsinki"
    ["Europe/Reykjavik"]="BIRK:Reykjavik"

    # ── EASTERN EUROPE ──
    ["Europe/Warsaw"]="EPWA:Warsaw"
    ["Europe/Prague"]="LKPR:Prague"
    ["Europe/Budapest"]="LHBP:Budapest"
    ["Europe/Bucharest"]="LROP:Bucharest"
    ["Europe/Sofia"]="LBSF:Sofia"
    ["Europe/Athens"]="LGAV:Athens"
    ["Europe/Istanbul"]="LTBA:Istanbul"
    ["Europe/Kiev"]="UKBB:Kyiv"
    ["Europe/Minsk"]="UMMS:Minsk"
    ["Europe/Riga"]="EVRA:Riga"
    ["Europe/Tallinn"]="EETN:Tallinn"
    ["Europe/Vilnius"]="EYVI:Vilnius"

    # ── RUSSIA ──
    ["Europe/Moscow"]="UUEE:Moscow"
    ["Asia/Yekaterinburg"]="USSS:Yekaterinburg"
    ["Asia/Novosibirsk"]="UNNT:Novosibirsk"
    ["Asia/Krasnoyarsk"]="UNKL:Krasnoyarsk"
    ["Asia/Irkutsk"]="UIII:Irkutsk"
    ["Asia/Vladivostok"]="UHWW:Vladivostok"

    # ── MIDDLE EAST ──
    ["Asia/Dubai"]="OMDB:Dubai"
    ["Asia/Abu_Dhabi"]="OMAA:Abu Dhabi"
    ["Asia/Riyadh"]="OERK:Riyadh"
    ["Asia/Kuwait"]="OKBK:Kuwait City"
    ["Asia/Baghdad"]="ORBI:Baghdad"
    ["Asia/Tehran"]="OIIE:Tehran"
    ["Asia/Beirut"]="OLBA:Beirut"
    ["Asia/Amman"]="OJAI:Amman"
    ["Asia/Jerusalem"]="LLBG:Tel Aviv"
    ["Asia/Qatar"]="OTBD:Doha"

    # ── SOUTH ASIA ──
    ["Asia/Karachi"]="OPKC:Karachi"
    ["Asia/Lahore"]="OPLA:Lahore"
    ["Asia/Kolkata"]="VABB:Mumbai"
    ["Asia/Dhaka"]="VGHS:Dhaka"
    ["Asia/Colombo"]="VCBI:Colombo"
    ["Asia/Kathmandu"]="VNKT:Kathmandu"

    # ── SOUTHEAST ASIA ──
    ["Asia/Bangkok"]="VTBS:Bangkok"
    ["Asia/Ho_Chi_Minh"]="VVTS:Ho Chi Minh City"
    ["Asia/Hanoi"]="VVNB:Hanoi"
    ["Asia/Phnom_Penh"]="VDPP:Phnom Penh"
    ["Asia/Kuala_Lumpur"]="WMKK:Kuala Lumpur"
    ["Asia/Singapore"]="WSSS:Singapore"
    ["Asia/Jakarta"]="WIII:Jakarta"
    ["Asia/Manila"]="RPLL:Manila"
    ["Asia/Yangon"]="VYYY:Yangon"

    # ── EAST ASIA ──
    ["Asia/Shanghai"]="ZSPD:Shanghai"
    ["Asia/Beijing"]="ZBAA:Beijing"
    ["Asia/Chongqing"]="ZUCK:Chongqing"
    ["Asia/Chengdu"]="ZUUU:Chengdu"
    ["Asia/Hong_Kong"]="VHHH:Hong Kong"
    ["Asia/Taipei"]="RCTP:Taipei"
    ["Asia/Seoul"]="RKSI:Seoul"
    ["Asia/Tokyo"]="RJTT:Tokyo"
    ["Asia/Osaka"]="RJBB:Osaka"
    ["Asia/Sapporo"]="RJCC:Sapporo"

    # ── OCEANIA ──
    ["Australia/Perth"]="YPPH:Perth"
    ["Australia/Darwin"]="YPDN:Darwin"
    ["Australia/Adelaide"]="YPAD:Adelaide"
    ["Australia/Brisbane"]="YBBN:Brisbane"
    ["Australia/Sydney"]="YSSY:Sydney"
    ["Australia/Melbourne"]="YMML:Melbourne"
    ["Pacific/Auckland"]="NZAA:Auckland"
    ["Pacific/Fiji"]="NFFN:Suva"
    ["Pacific/Guam"]="PGUM:Guam"

    # ── AFRICA ──
    ["Africa/Casablanca"]="GMMN:Casablanca"
    ["Africa/Algiers"]="DAAG:Algiers"
    ["Africa/Tunis"]="DTTA:Tunis"
    ["Africa/Cairo"]="HECA:Cairo"
    ["Africa/Lagos"]="DNMM:Lagos"
    ["Africa/Accra"]="DGAA:Accra"
    ["Africa/Nairobi"]="HKJK:Nairobi"
    ["Africa/Addis_Ababa"]="HAAB:Addis Ababa"
    ["Africa/Dar_es_Salaam"]="HTDA:Dar es Salaam"
    ["Africa/Johannesburg"]="FAOR:Johannesburg"
    ["Africa/Cape_Town"]="FACT:Cape Town"
    ["Africa/Khartoum"]="HSSS:Khartoum"
    ["Africa/Kinshasa"]="FZAA:Kinshasa"
    ["Africa/Luanda"]="FNLU:Luanda"
)

# ── LOCATION DETECTION FUNCTION ──
detect_location() {
    local sys_tz
    sys_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "")

    if [ -z "$sys_tz" ]; then
        echo ""
        return
    fi

    local entry="${TZ_ICAO[$sys_tz]}"
    if [ -n "$entry" ]; then
        echo "$entry"  # returns "ICAO:City"
    else
        echo ""
    fi
}

# ── LOCATION PROMPT ──
configure_location() {
    echo ""
    echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${G}${B}  ║         CANOPTEK ATMOSPHERIC INTERFACE — CALIBRATION         ║${NC}"
    echo -e "${G}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DG}  Location data is used to retrieve METAR weather conditions for${NC}"
    echo -e "${DG}  the SDDM login display. Data is fetched from aviationweather.gov${NC}"
    echo -e "${DG}  at boot only. Nothing is stored or transmitted beyond that request.${NC}"
    echo ""

    # Try auto-detect
    local detected
    detected="$(detect_location)"
    local detected_icao=""
    local detected_city=""

    if [ -n "$detected" ]; then
        detected_icao="${detected%%:*}"
        detected_city="${detected##*:}"
        echo -e "  ${G}✓${NC} System timezone detected — nearest major station: ${B}${detected_city}${NC} (${detected_icao})"
        echo ""
    fi

    echo -e "  ${G}[1]${NC} Auto-detect from system timezone${detected_city:+ — ${detected_city} (${detected_icao})}"
    echo -e "  ${G}[2]${NC} Enter city or airport name manually"
    echo -e "  ${G}[3]${NC} No location — disable weather display"
    echo ""
    echo -en "  ${G}?${NC} Choice [1/2/3]: "
    read -r loc_choice

    case "$loc_choice" in
        3)
            echo ""
            print_info "Weather display disabled. Login screen will show no signal."
            echo "DISABLED" > /tmp/necrodermis-icao
            ;;
        2)
            echo ""
            echo -e "${DG}  Enter your nearest large city, or if you know it, your airport${NC}"
            echo -e "${DG}  ICAO code directly (e.g. EGLL for London Heathrow).${NC}"
            echo ""
            echo -en "  ${G}?${NC} City or ICAO: "
            read -r user_input

            # Check if it looks like a raw ICAO (3-4 uppercase letters)
            if [[ "$user_input" =~ ^[A-Z]{3,4}$ ]]; then
                echo "$user_input" > /tmp/necrodermis-icao
                print_ok "ICAO set to ${user_input}"
            else
                # Try to match city name against our table
                local matched_icao=""
                local matched_city=""
                local input_lower
                input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

                for key in "${!TZ_ICAO[@]}"; do
                    local entry="${TZ_ICAO[$key]}"
                    local city="${entry##*:}"
                    local city_lower
                    city_lower=$(echo "$city" | tr '[:upper:]' '[:lower:]')
                    if [[ "$city_lower" == *"$input_lower"* ]]; then
                        matched_icao="${entry%%:*}"
                        matched_city="$city"
                        break
                    fi
                done

                if [ -n "$matched_icao" ]; then
                    echo ""
                    echo -e "  ${G}✓${NC} Matched: ${B}${matched_city}${NC} → ${matched_icao}"
                    echo -en "  ${G}?${NC} Use this? [Y/n]: "
                    read -r confirm_match
                    if [[ ! "$confirm_match" =~ ^[nN] ]]; then
                        echo "$matched_icao" > /tmp/necrodermis-icao
                        print_ok "Location set to ${matched_city} (${matched_icao})"
                    else
                        echo -en "  ${G}?${NC} Enter ICAO code directly: "
                        read -r raw_icao
                        echo "$raw_icao" > /tmp/necrodermis-icao
                        print_ok "ICAO set to ${raw_icao}"
                    fi
                else
                    echo ""
                    print_info "No match found for '${user_input}'."
                    echo -e "${DG}  Find your nearest airport ICAO at: https://ourairports.com${NC}"
                    echo -en "  ${G}?${NC} Enter ICAO code directly (or leave blank to disable): "
                    read -r raw_icao
                    if [ -z "$raw_icao" ]; then
                        echo "DISABLED" > /tmp/necrodermis-icao
                        print_info "Weather display disabled."
                    else
                        echo "$raw_icao" > /tmp/necrodermis-icao
                        print_ok "ICAO set to ${raw_icao}"
                    fi
                fi
            fi
            ;;
        *)
            # Auto-detect (default)
            if [ -n "$detected_icao" ]; then
                echo "$detected_icao" > /tmp/necrodermis-icao
                print_ok "Location set to ${detected_city} (${detected_icao})"
            else
                echo ""
                print_info "Could not auto-detect location from timezone."
                print_info "Falling back to manual entry."
                configure_location
            fi
            ;;
    esac

    # Apply to weather script
    local final_icao
    final_icao=$(cat /tmp/necrodermis-icao 2>/dev/null)
    rm -f /tmp/necrodermis-icao

    if [ "$final_icao" = "DISABLED" ] || [ -z "$final_icao" ]; then
        sudo sed -i 's/ICAO="CYWG"/ICAO=""/' \
            /usr/share/sddm/themes/simple_sddm_2/weather.sh
        print_info "Weather fetching disabled — login screen will show no signal"
    else
        sudo sed -i "s/ICAO=\"CYWG\"/ICAO=\"${final_icao}\"/" \
            /usr/share/sddm/themes/simple_sddm_2/weather.sh
        sudo bash /usr/share/sddm/themes/simple_sddm_2/weather.sh 2>/dev/null \
            && print_ok "Weather fetched successfully" \
            || print_info "Weather fetch failed — will retry at next boot"
    fi
}
