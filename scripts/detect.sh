#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — DETECTION UTILITIES
# Sourced by install.sh — do not run directly
# ════════════════════════════════════════════════════════════

detect_distro() {
    # ── Arch family ───────────────────────────────────────────────────────────
    if grep -qi "cachyos" /etc/os-release 2>/dev/null; then echo "cachyos"; return
    elif grep -qi "manjaro" /etc/os-release 2>/dev/null; then echo "manjaro"; return
    elif grep -qi "endeavouros" /etc/os-release 2>/dev/null; then echo "arch"; return
    elif grep -qi "^ID=arch" /etc/os-release 2>/dev/null; then echo "arch"; return
    elif grep -qi "arch" /etc/os-release 2>/dev/null; then echo "arch"; return
    fi

    # ── Fedora ────────────────────────────────────────────────────────────────
    if grep -qi "^ID=fedora" /etc/os-release 2>/dev/null; then
        echo "fedora"; return
    fi

    # ── openSUSE Tumbleweed  (not Leap — Hyprland only in Tumbleweed) ─────────
    if grep -qi "tumbleweed" /etc/os-release 2>/dev/null; then
        echo "opensuse"; return
    fi

    # ── Void Linux ────────────────────────────────────────────────────────────
    if grep -qi "^ID=void" /etc/os-release 2>/dev/null; then
        echo "void"; return
    fi

    echo "unknown"
}

# Returns the canonical package manager for the current distro
detect_pkg_manager() {
    case "$(detect_distro)" in
        arch|cachyos|manjaro) echo "pacman" ;;
        fedora)               echo "dnf"    ;;
        opensuse)             echo "zypper" ;;
        void)                 echo "xbps"   ;;
        *)                    echo "unknown" ;;
    esac
}

# Returns true if distro is Arch-family
is_arch_family() {
    case "$(detect_distro)" in
        arch|cachyos|manjaro) return 0 ;;
        *) return 1 ;;
    esac
}

get_aur_helper() {
    if command -v yay &>/dev/null; then echo "yay"
    elif command -v paru &>/dev/null; then echo "paru"
    else echo ""
    fi
}

detect_cpu_level() {
    if grep -q "avx512" /proc/cpuinfo 2>/dev/null; then echo "v4"
    elif grep -q "avx2" /proc/cpuinfo 2>/dev/null; then echo "v3"
    elif grep -q "sse4_2" /proc/cpuinfo 2>/dev/null; then echo "v2"
    else echo "v1"
    fi
}

detect_location() {
    local sys_tz
    sys_tz=$(timedatectl show --property=Timezone --value 2>/dev/null \
             || cat /etc/timezone 2>/dev/null \
             || echo "")
    [ -z "$sys_tz" ] && echo "" && return
    echo "${TZ_ICAO[$sys_tz]:-}"
}

detect_location_ip() {
    local geo_json city icao_entry matched_icao matched_city city_lower input_lower key entry
    geo_json=$(curl -sf --max-time 6 "https://ipinfo.io/json" 2>/dev/null) || return 1
    city=$(echo "$geo_json" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); print(d.get('city',''))" 2>/dev/null)
    [ -z "$city" ] && return 1

    input_lower=$(echo "$city" | tr '[:upper:]' '[:lower:]')
    for key in "${!TZ_ICAO[@]}"; do
        entry="${TZ_ICAO[$key]}"
        city_lower=$(echo "${entry##*:}" | tr '[:upper:]' '[:lower:]')
        if [[ "$city_lower" == *"$input_lower"* ]] || [[ "$input_lower" == *"$city_lower"* ]]; then
            matched_icao="${entry%%:*}"
            matched_city="${entry##*:}"
            break
        fi
    done
    [ -z "$matched_icao" ] && return 1
    echo "${matched_icao}:${matched_city}"
}

detect_gpu() {
    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -i "vga\|3d\|display")
    if echo "$gpu_info" | grep -qi "nvidia"; then echo "nvidia"
    elif echo "$gpu_info" | grep -qi "amd\|radeon"; then echo "amd"
    elif echo "$gpu_info" | grep -qi "intel"; then echo "intel"
    else echo "unknown"
    fi
}
