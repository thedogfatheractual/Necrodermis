#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS  //  scripts/pkg.sh
# ────────────────────────────────────────────────────────────
# Cross-distro package abstraction layer.
# Sourced by install.sh after detect.sh — do not run directly.
#
# Supported:
#   arch / cachyos / manjaro  →  pacman + yay/paru
#   fedora                    →  dnf + copr
#   opensuse                  →  zypper + OBS
#   void                      →  xbps-install
#
# Public interface:
#   necro_pkg          component pkg...       # same name all distros
#   necro_pkg_map      component k:v...       # per-distro name overrides
#   necro_pkg_aur      component pkg...       # AUR + equivalents
#   necro_pkg_critical component pkg...       # fatal on failure
# ════════════════════════════════════════════════════════════

# ── Resolved once at source time ─────────────────────────────────────────────
NECRO_DISTRO="${NECRO_DISTRO:-$(detect_distro)}"
NECRO_PKG_MGR="${NECRO_PKG_MGR:-$(detect_pkg_manager)}"

# ════════════════════════════════════════════════════════════
# PACKAGE NAME MAP
# ────────────────────────────────────────────────────────────
# Keys: "distro:canonical-name"  →  actual package name
# Only entries that DIFFER from canonical need to be listed.
# If no entry exists, canonical name is used as-is.
# ════════════════════════════════════════════════════════════
declare -A NECRO_PKG_MAP=(
    # ── rofi ──────────────────────────────────────────────────────────────────
    ["arch:rofi"]="rofi-wayland"
    ["cachyos:rofi"]="rofi-wayland"
    ["manjaro:rofi"]="rofi-wayland"
    ["void:rofi"]="rofi"

    # ── sddm ──────────────────────────────────────────────────────────────────
    # same everywhere: sddm

    # ── swaync ────────────────────────────────────────────────────────────────
    ["arch:swaync"]="swaynotificationcenter"
    ["cachyos:swaync"]="swaynotificationcenter"
    ["manjaro:swaync"]="swaynotificationcenter"
    ["fedora:swaync"]="swaynotificationcenter"
    ["opensuse:swaync"]="SwayNotificationCenter"
    ["void:swaync"]="swaynotificationcenter"

    # ── nerd fonts ────────────────────────────────────────────────────────────
    ["arch:nerd-fonts-terminess"]="ttf-terminus-nerd"
    ["cachyos:nerd-fonts-terminess"]="ttf-terminus-nerd"
    ["manjaro:nerd-fonts-terminess"]="ttf-terminus-nerd"
    ["fedora:nerd-fonts-terminess"]="terminus-fonts"
    ["opensuse:nerd-fonts-terminess"]="terminus-fonts"
    ["void:nerd-fonts-terminess"]="terminus-font"

    ["arch:nerd-fonts-iosevka"]="ttf-iosevka-nerd"
    ["cachyos:nerd-fonts-iosevka"]="ttf-iosevka-nerd"
    ["manjaro:nerd-fonts-iosevka"]="ttf-iosevka-nerd"
    ["fedora:nerd-fonts-iosevka"]="iosevka-fonts"
    ["opensuse:nerd-fonts-iosevka"]="iosevka-fonts"
    ["void:nerd-fonts-iosevka"]="font-iosevka"

    ["arch:nerd-fonts-meslo"]="ttf-meslo-nerd"
    ["cachyos:nerd-fonts-meslo"]="ttf-meslo-nerd"
    ["manjaro:nerd-fonts-meslo"]="ttf-meslo-nerd"
    ["fedora:nerd-fonts-meslo"]="meslo-lg-fonts"
    ["opensuse:nerd-fonts-meslo"]="meslo-lg-fonts"
    ["void:nerd-fonts-meslo"]="font-meslo-fonts"

    # ── hyprland stack ────────────────────────────────────────────────────────
    ["void:hyprland"]="hyprland"
    ["fedora:hyprpaper"]="hyprpaper"
    ["opensuse:hyprpaper"]="hyprpaper"
    ["void:hyprpaper"]="hyprpaper"

    # ── xdg-desktop-portal ────────────────────────────────────────────────────
    ["arch:xdg-desktop-portal-hyprland"]="xdg-desktop-portal-hyprland"
    ["fedora:xdg-desktop-portal-hyprland"]="xdg-desktop-portal-hyprland"
    ["opensuse:xdg-desktop-portal-hyprland"]="xdg-desktop-portal-hyprland"
    ["void:xdg-desktop-portal-hyprland"]="xdg-desktop-portal-hyprland"

    # ── polkit ────────────────────────────────────────────────────────────────
    ["arch:polkit-kde-agent"]="polkit-kde-agent"
    ["fedora:polkit-kde-agent"]="polkit-kde"
    ["opensuse:polkit-kde-agent"]="polkit-kde-agent-6"
    ["void:polkit-kde-agent"]="polkit-kde-agent"

    # ── pipewire ──────────────────────────────────────────────────────────────
    ["fedora:pipewire-pulse"]="pipewire-pulseaudio"
    ["opensuse:pipewire-pulse"]="pipewire-pulseaudio"
    ["void:pipewire-pulse"]="pipewire-pulse"

    # ── python ────────────────────────────────────────────────────────────────
    ["arch:python3"]="python"
    ["cachyos:python3"]="python"
    ["manjaro:python3"]="python"

    # ── brightnessctl ─────────────────────────────────────────────────────────
    # same everywhere

    # ── network manager ───────────────────────────────────────────────────────
    ["arch:networkmanager-applet"]="network-manager-applet"
    ["cachyos:networkmanager-applet"]="network-manager-applet"
    ["manjaro:networkmanager-applet"]="network-manager-applet"
)

# ════════════════════════════════════════════════════════════
# INTERNAL  //  resolve canonical name → actual package name
# ════════════════════════════════════════════════════════════
_necro_resolve_pkg() {
    local pkg="$1"
    local key="${NECRO_DISTRO}:${pkg}"
    echo "${NECRO_PKG_MAP[$key]:-$pkg}"
}

_necro_resolve_pkgs() {
    local resolved=()
    for pkg in "$@"; do
        resolved+=("$(_necro_resolve_pkg "$pkg")")
    done
    echo "${resolved[@]}"
}

# ════════════════════════════════════════════════════════════
# INTERNAL  //  raw install dispatch per package manager
# ════════════════════════════════════════════════════════════
_necro_do_install() {
    local component="$1"; shift
    local pkgs=("$@")

    case "$NECRO_PKG_MGR" in
        pacman)
            sudo pacman -S --needed --noconfirm "${pkgs[@]}"
            ;;
        dnf)
            sudo dnf install -y "${pkgs[@]}"
            ;;
        zypper)
            sudo zypper install -y --no-confirm "${pkgs[@]}"
            ;;
        xbps)
            sudo xbps-install -Sy "${pkgs[@]}"
            ;;
        *)
            print_err "${component}  //  unknown package manager: ${NECRO_PKG_MGR}"
            return 1
            ;;
    esac
}

# ════════════════════════════════════════════════════════════
# NECRO_PKG  //  standard install, same canonical name everywhere
# ════════════════════════════════════════════════════════════
necro_pkg() {
    local component="$1"; shift
    local resolved
    resolved=($(_necro_resolve_pkgs "$@"))

    if _necro_do_install "$component" "${resolved[@]}" 2>&1; then
        necro_log "OK" "$component" "${NECRO_PKG_MGR}: ${resolved[*]}"
        print_ok "${component}  ${DG}//  installed${NC}"
    else
        necro_log "FAIL" "$component" "${NECRO_PKG_MGR} failed: ${resolved[*]}"
        print_err "${component}  //  install failed — engaging triage"
        necro_triage "$component" \
            "${NECRO_PKG_MGR} install ${resolved[*]}" \
            "${NECRO_PKG_MGR}" "false" || true
    fi
}

necro_pkg_critical() {
    local component="$1"; shift
    local resolved
    resolved=($(_necro_resolve_pkgs "$@"))

    if _necro_do_install "$component" "${resolved[@]}" 2>&1; then
        necro_log "OK" "$component" "${NECRO_PKG_MGR}: ${resolved[*]}"
        print_ok "${component}  ${DG}//  installed${NC}"
    else
        necro_log "FAIL" "$component" "${NECRO_PKG_MGR} failed (CRITICAL): ${resolved[*]}"
        print_err "${component}  //  install failed  ${R}[CRITICAL]${NC} — engaging triage"
        necro_triage "$component" \
            "${NECRO_PKG_MGR} install ${resolved[*]}" \
            "${NECRO_PKG_MGR}" "critical"
    fi
}

# ════════════════════════════════════════════════════════════
# NECRO_PKG_MAP  //  explicit per-distro name overrides inline
# Usage: necro_pkg_map "component" "arch:pkgA" "fedora:pkgB" "void:pkgC"
# Any distro not listed falls back to the arch: entry, then canonical.
# ════════════════════════════════════════════════════════════
necro_pkg_map() {
    local component="$1"; shift
    local pkg=""

    # Find the entry for current distro
    for entry in "$@"; do
        local key="${entry%%:*}"
        local val="${entry##*:}"
        if [[ "$key" == "$NECRO_DISTRO" ]]; then
            pkg="$val"
            break
        fi
    done

    # Fallback: arch entry covers all Arch-family
    if [[ -z "$pkg" ]] && is_arch_family; then
        for entry in "$@"; do
            [[ "${entry%%:*}" == "arch" ]] && pkg="${entry##*:}" && break
        done
    fi

    if [[ -z "$pkg" ]]; then
        print_skip "${component}  //  no package mapping for ${NECRO_DISTRO}"
        necro_log "SKIP" "$component" "No pkg map entry for ${NECRO_DISTRO}"
        return 0
    fi

    necro_pkg "$component" "$pkg"
}

# ════════════════════════════════════════════════════════════
# NECRO_PKG_AUR  //  AUR on Arch, equivalent on others
# ════════════════════════════════════════════════════════════
#
# AUR package equivalents per distro:
#
#   sddm-astronaut-theme:
#     arch    → yay -S sddm-astronaut-theme
#     fedora  → copr + manual build (stub — prints instruction)
#     opensuse→ OBS + manual build (stub — prints instruction)
#     void    → manual build (stub — prints instruction)
#
#   All AUR-only packages that have no distro equivalent
#   get a clear "install manually" message rather than silent skip.
#
# ════════════════════════════════════════════════════════════

# AUR equivalent lookup — Copr/OBS repo slugs
declare -A NECRO_AUR_COPR=(
    ["gum"]="charmbracelet/tap"
)
declare -A NECRO_AUR_OBS=(
    ["gum"]="utilities"
)

necro_pkg_aur() {
    local component="$1"; shift
    local pkgs=("$@")

    case "$NECRO_DISTRO" in
        # ── Arch family — use yay/paru ────────────────────────────────────────
        arch|cachyos|manjaro)
            local aur_helper
            aur_helper="$(get_aur_helper)"
            if [[ -z "$aur_helper" ]]; then
                necro_log "SKIP" "$component" "No AUR helper — skipped: ${pkgs[*]}"
                print_skip "${component}  //  no AUR helper available"
                return 0
            fi
            if $aur_helper -S --needed --noconfirm "${pkgs[@]}" 2>&1; then
                necro_log "OK" "$component" "AUR: ${pkgs[*]}"
                print_ok "${component}  ${DG}//  AUR packages installed${NC}"
            else
                necro_log "FAIL" "$component" "AUR failed: ${pkgs[*]}"
                print_err "${component}  //  AUR failed — engaging triage"
                necro_triage "$component" \
                    "$aur_helper -S --needed --noconfirm ${pkgs[*]}" \
                    "yay" "false" || true
            fi
            ;;

        # ── Fedora — COPR where available, manual otherwise ──────────────────
        fedora)
            for pkg in "${pkgs[@]}"; do
                local copr="${NECRO_AUR_COPR[$pkg]:-}"
                if [[ -n "$copr" ]]; then
                    print_info "Enabling COPR  //  ${copr}"
                    sudo dnf copr enable -y "$copr" 2>/dev/null || true
                    if sudo dnf install -y "$pkg" 2>/dev/null; then
                        necro_log "OK" "$component" "COPR: $pkg"
                        print_ok "${component}  ${DG}//  ${pkg} installed via COPR${NC}"
                    else
                        _necro_aur_manual_fallback "$component" "$pkg" "fedora"
                    fi
                else
                    _necro_aur_manual_fallback "$component" "$pkg" "fedora"
                fi
            done
            ;;

        # ── openSUSE — OBS where available, manual otherwise ─────────────────
        opensuse)
            for pkg in "${pkgs[@]}"; do
                local obs="${NECRO_AUR_OBS[$pkg]:-}"
                if [[ -n "$obs" ]]; then
                    print_info "Adding OBS repo  //  home:${obs}"
                    sudo zypper addrepo -f \
                        "https://download.opensuse.org/repositories/home:${obs}/openSUSE_Tumbleweed/home:${obs}.repo" \
                        "$obs" 2>/dev/null || true
                    sudo zypper --gpg-auto-import-keys refresh 2>/dev/null || true
                    if sudo zypper install -y --no-confirm "$pkg" 2>/dev/null; then
                        necro_log "OK" "$component" "OBS: $pkg"
                        print_ok "${component}  ${DG}//  ${pkg} installed via OBS${NC}"
                    else
                        _necro_aur_manual_fallback "$component" "$pkg" "opensuse"
                    fi
                else
                    _necro_aur_manual_fallback "$component" "$pkg" "opensuse"
                fi
            done
            ;;

        # ── Void — xbps or manual ─────────────────────────────────────────────
        void)
            for pkg in "${pkgs[@]}"; do
                if sudo xbps-install -Sy "$pkg" 2>/dev/null; then
                    necro_log "OK" "$component" "xbps: $pkg"
                    print_ok "${component}  ${DG}//  ${pkg} installed${NC}"
                else
                    _necro_aur_manual_fallback "$component" "$pkg" "void"
                fi
            done
            ;;
    esac
}

# ── Manual fallback — clear instruction, not silent skip ─────────────────────
_necro_aur_manual_fallback() {
    local component="$1"
    local pkg="$2"
    local distro="$3"

    necro_log "SKIP" "$component" "AUR-only — manual install required: ${pkg} on ${distro}"
    echo ""
    echo -e "  ${Y}  ──────────────────────────────────────────────────────────${NC}"
    echo -e "  ${Y}  MANUAL INSTALL REQUIRED  //  ${component}${NC}"
    echo -e "  ${DG}  Package '${pkg}' has no automated equivalent on ${distro}.${NC}"
    echo -e "  ${DG}  Install manually, then re-run the installer to continue.${NC}"
    echo ""

    case "$pkg" in
        sddm-astronaut-theme)
            echo -e "  ${DG}  Source:  https://github.com/Keyitdev/sddm-astronaut-theme${NC}"
            echo -e "  ${DG}  Install to: /usr/share/sddm/themes/sddm-astronaut-theme${NC}"
            ;;
        *)
            echo -e "  ${DG}  AUR source:  https://aur.archlinux.org/packages/${pkg}${NC}"
            echo -e "  ${DG}  Build from source or find a ${distro} equivalent.${NC}"
            ;;
    esac
    echo -e "  ${Y}  ──────────────────────────────────────────────────────────${NC}"
    echo ""
}
