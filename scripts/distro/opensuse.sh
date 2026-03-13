#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS  //  scripts/distro/opensuse.sh
# openSUSE Tumbleweed bootstrap
# Leap is NOT supported — Hyprland requires Tumbleweed
# ════════════════════════════════════════════════════════════

necro_distro_bootstrap() {
    print_section "OPENSUSE BOOTSTRAP  //  VERIFYING SUBSTRATE"

    # Tumbleweed confirmation
    if ! grep -qi "tumbleweed" /etc/os-release 2>/dev/null; then
        print_err "openSUSE Leap detected  //  NECRODERMIS requires Tumbleweed"
        print_err "Hyprland is not available in Leap repos"
        exit 1
    fi
    print_ok "Tumbleweed confirmed"

    # Refresh repos
    print_info "Refreshing repos..."
    sudo zypper --gpg-auto-import-keys refresh 2>/dev/null || true

    # Wayland + Hyprland OBS repo
    local HYPR_REPO="https://download.opensuse.org/repositories/wayland/openSUSE_Tumbleweed/wayland.repo"
    if ! sudo zypper repos 2>/dev/null | grep -q "wayland"; then
        print_info "Adding OBS wayland repo  //  Hyprland ecosystem"
        sudo zypper addrepo -f "$HYPR_REPO" wayland 2>/dev/null \
            || print_err "wayland OBS repo failed  //  Hyprland install may fail"
        sudo zypper --gpg-auto-import-keys refresh 2>/dev/null || true
    else
        print_ok "wayland OBS repo already present"
    fi

    # M17N / fonts OBS repo
    local FONTS_REPO="https://download.opensuse.org/repositories/M17N/openSUSE_Tumbleweed/M17N.repo"
    if ! sudo zypper repos 2>/dev/null | grep -q "M17N"; then
        print_info "Adding OBS M17N repo  //  extended font support"
        sudo zypper addrepo -f "$FONTS_REPO" M17N 2>/dev/null || true
        sudo zypper --gpg-auto-import-keys refresh 2>/dev/null || true
    fi

    # zypper dup — Tumbleweed should be fully up to date before major installs
    print_info "Checking for pending Tumbleweed updates..."
    local pending
    pending=$(sudo zypper list-updates 2>/dev/null | grep -c "^v" || echo "0")
    if (( pending > 0 )); then
        echo ""
        echo -e "  ${Y}  ${pending} pending updates detected.${NC}"
        echo -e "  ${DG}  It is strongly recommended to run 'sudo zypper dup' before proceeding.${NC}"
        echo ""
        if command -v gum &>/dev/null && [[ -t 0 ]]; then
            gum confirm "Run zypper dup now?" \
                --affirmative="  YES — UPDATE FIRST  " \
                --negative="  NO  — CONTINUE ANYWAY  " \
            && sudo zypper dup -y || true
        fi
    fi

    print_ok "openSUSE Tumbleweed bootstrap complete"
}
