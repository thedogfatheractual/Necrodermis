#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS  //  scripts/distro/fedora.sh
# Fedora 38+ bootstrap
# ════════════════════════════════════════════════════════════

# Minimum supported Fedora version
FEDORA_MIN=38

necro_distro_bootstrap() {
    print_section "FEDORA BOOTSTRAP  //  VERIFYING SUBSTRATE"

    # Version check
    local ver
    ver=$(rpm -E %fedora 2>/dev/null || echo "0")
    if (( ver < FEDORA_MIN )); then
        print_err "Fedora ${ver} detected  //  minimum supported: ${FEDORA_MIN}"
        print_err "Upgrade to Fedora ${FEDORA_MIN}+ before running NECRODERMIS"
        exit 1
    fi
    print_ok "Fedora ${ver} confirmed"

    # Update first
    print_info "Syncing repos..."
    sudo dnf makecache --quiet 2>/dev/null || true

    # dnf plugins — copr support
    if ! rpm -q dnf-plugins-core &>/dev/null; then
        print_info "Installing dnf-plugins-core  //  required for COPR"
        sudo dnf install -y dnf-plugins-core
    fi

    # RPM Fusion — provides a number of packages missing from main Fedora repos
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        print_info "Enabling RPM Fusion  //  free + nonfree"
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
            2>/dev/null || print_err "RPM Fusion install failed  //  some packages may be unavailable"
    fi

    # Hyprland available in official Fedora 38+ repos — no COPR needed
    print_ok "Hyprland available in official repos  //  no COPR required"

    # COPR: solopasha/hyprland — extra Hyprland ecosystem packages
    print_info "Enabling COPR  //  solopasha/hyprland (hyprland ecosystem extras)"
    sudo dnf copr enable -y solopasha/hyprland 2>/dev/null \
        || print_err "solopasha/hyprland COPR failed  //  some components may be unavailable"

    # COPR: erikreider/SwayNotificationCenter — swaync
    print_info "Enabling COPR  //  erikreider/SwayNotificationCenter"
    sudo dnf copr enable -y erikreider/SwayNotificationCenter 2>/dev/null \
        || print_err "swaync COPR failed  //  notifications component will be skipped"

    print_ok "Fedora bootstrap complete"
}
