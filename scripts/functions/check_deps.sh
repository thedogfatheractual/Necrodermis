#!/usr/bin/env bash
# Necrodermis — scripts/functions/check_deps.sh

check_deps() {
    print_section "PRE-FLIGHT DIAGNOSTIC  //  SCANNING TOMB SYSTEMS"
    echo ""

    local deps=(git curl gcc make python3 gum)
    local missing=()

    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            print_ok "${dep}  ${DG}//  node confirmed${NC}"
        else
            print_err "${dep}  — fault detected"
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        echo ""
        print_info "All prerequisite nodes nominal  ${DG}//  proceeding${NC}"
        echo ""
        return 0
    fi

    echo ""
    echo -e "  ${R}  FAULT REPORT: ${#missing[@]} prerequisite(s) missing${NC}"
    echo ""

    if confirm "Attempt automated repair?"; then
        local pkgs=()
        for dep in "${missing[@]}"; do
            case "$dep" in
                gcc|make) pkgs+=("base-devel") ;;
                python3)  pkgs+=("python") ;;
                gum)      pkgs+=("gum") ;;
                *)        pkgs+=("$dep") ;;
            esac
        done
        local unique_pkgs=($(printf '%s\n' "${pkgs[@]}" | sort -u))
        sudo pacman -S --needed --noconfirm "${unique_pkgs[@]}"
        echo ""
        print_ok "Repair sequence complete  ${DG}//  resuming awakening${NC}"
        echo ""
    else
        echo -e "\n  ${R}  Prerequisites unresolved. The tomb cannot wake.${NC}\n"
        exit 1
    fi
}
