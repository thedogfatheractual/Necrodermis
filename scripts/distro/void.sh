#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS  //  scripts/distro/void.sh
# Void Linux bootstrap
# ════════════════════════════════════════════════════════════

necro_distro_bootstrap() {
    print_section "VOID BOOTSTRAP  //  VERIFYING SUBSTRATE"

    # Confirm xbps is present — should always be true on Void
    if ! command -v xbps-install &>/dev/null; then
        print_err "xbps-install not found  //  are you actually running Void?"
        exit 1
    fi

    # Sync repos
    print_info "Syncing xbps repos..."
    sudo xbps-install -S 2>/dev/null || true

    # void-repo-nonfree — required for some firmware + fonts
    if ! xbps-query void-repo-nonfree &>/dev/null; then
        print_info "Enabling void-repo-nonfree  //  extended font + firmware support"
        sudo xbps-install -Sy void-repo-nonfree 2>/dev/null \
            || print_err "void-repo-nonfree failed  //  some packages may be unavailable"
        sudo xbps-install -S 2>/dev/null || true
    else
        print_ok "void-repo-nonfree already enabled"
    fi

    # void-repo-multilib — optional, needed only on x86_64 for Steam
    if [[ "$(uname -m)" == "x86_64" ]]; then
        if ! xbps-query void-repo-multilib &>/dev/null; then
            print_info "Enabling void-repo-multilib  //  x86_64 · Steam support"
            sudo xbps-install -Sy void-repo-multilib 2>/dev/null || true
            sudo xbps-install -S 2>/dev/null || true
        fi
    fi

    # Update installed packages
    print_info "Updating installed packages..."
    sudo xbps-install -Su 2>/dev/null || true

    print_ok "Void bootstrap complete"
}
