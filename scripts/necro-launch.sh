#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS  //  scripts/necro-launch.sh
# ────────────────────────────────────────────────────────────
# Entry point. Handles gum acquisition, mode selection,
# and hands off to install.sh with the correct flags.
#
# Usage:
#   bash necro-launch.sh              — interactive launch
#   bash necro-launch.sh --dots       — non-interactive, theme only
#   bash necro-launch.sh --full       — non-interactive, full install
#   bash necro-launch.sh --debug      — pass debug flag through
# ════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SH="$REPO_ROOT/install.sh"

# ── Colour palette ────────────────────────────────────────────────────────────
G='\033[0;32m'
DG='\033[2;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[1m'
NC='\033[0m'
CLS='\033[2J\033[H'

# ── Arg parsing ───────────────────────────────────────────────────────────────
MODE=""
PASSTHROUGH_FLAGS=()
for arg in "$@"; do
    case "$arg" in
        --dots)  MODE="dots"  ;;
        --full)  MODE="full"  ;;
        --debug) PASSTHROUGH_FLAGS+=("--debug") ;;
    esac
done

# ── Sanity: install.sh must exist ────────────────────────────────────────────
if [[ ! -f "$INSTALL_SH" ]]; then
    echo -e "\n  ${R}LAUNCH FAILURE${NC}  //  install.sh not found at ${INSTALL_SH}"
    echo -e "  ${DG}  Run from the repository root  //  bash scripts/necro-launch.sh${NC}\n"
    exit 1
fi

# ════════════════════════════════════════════════════════════
# GUM ACQUISITION  //  hardened, no gum = no TUI, not no installer
# ════════════════════════════════════════════════════════════
GUM_AVAILABLE=false

_acquire_gum() {
    if command -v gum &>/dev/null; then
        GUM_AVAILABLE=true
        return 0
    fi

    echo -e "\n  ${Y}──${NC}  gum not found  //  acquiring\n"

    if command -v pacman &>/dev/null; then
        if sudo pacman -S --needed --noconfirm gum 2>/dev/null; then
            GUM_AVAILABLE=true
            return 0
        fi
    fi

    # Fallback: go install (if go is present — CachyOS sometimes ships it)
    if command -v go &>/dev/null; then
        echo -e "  ${DG}  pacman failed  //  attempting go install${NC}"
        if GOPATH="$HOME/.local/go" go install github.com/charmbracelet/gum@latest 2>/dev/null; then
            export PATH="$PATH:$HOME/.local/go/bin"
            command -v gum &>/dev/null && GUM_AVAILABLE=true && return 0
        fi
    fi

    echo -e "  ${Y}──${NC}  gum unavailable  //  falling back to plain select\n"
    GUM_AVAILABLE=false
    return 0   # not fatal — TTY fallback handles it
}

# ════════════════════════════════════════════════════════════
# SPLASH
# ════════════════════════════════════════════════════════════
_splash() {
    printf "${CLS}"
    echo ""
    echo -e "${DG}  ╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${DG}  ║${NC}                                                                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}${B}  ███╗   ██╗███████╗ ██████╗██████╗  ██████╗ ${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}${B}  ████╗  ██║██╔════╝██╔════╝██╔══██╗██╔═══██╗${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}${B}  ██╔██╗ ██║█████╗  ██║     ██████╔╝██║   ██║${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}${B}  ██║╚██╗██║██╔══╝  ██║     ██╔══██╗██║   ██║${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}${B}  ██║ ╚████║███████╗╚██████╗██║  ██║╚██████╔╝${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}${B}  ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}  ██████╗ ███████╗██████╗ ███╗   ███╗██╗███████╗${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}  ██╔══██╗██╔════╝██╔══██╗████╗ ████║██║██╔════╝${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}  ██║  ██║█████╗  ██████╔╝██╔████╔██║██║███████╗${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}  ██║  ██║██╔══╝  ██╔══██╗██║╚██╔╝██║██║╚════██║${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}  ██████╔╝███████╗██║  ██║██║ ╚═╝ ██║██║███████║${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${G}  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚══════╝${NC}                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}                                                                  ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${DG}  STASIS DURATION: 60,247,891 YRS  //  TOMB INTEGRITY NOMINAL${NC}    ${DG}║${NC}"
    echo -e "${DG}  ║${NC}  ${DG}  AWAITING OPERATOR DIRECTIVE                               ${NC}    ${DG}║${NC}"
    echo -e "${DG}  ║${NC}                                                                  ${DG}║${NC}"
    echo -e "${DG}  ╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local ver=""
    [[ -f "$SCRIPT_DIR/VERSION" ]] && ver="  v$(cat "$SCRIPT_DIR/VERSION")"
    [[ -f "$SCRIPT_DIR/../VERSION" ]] && ver="  v$(cat "$SCRIPT_DIR/../VERSION")"
    echo -e "  ${DG}  https://github.com/thedogfatheractual/Necrodermis${ver}${NC}"
    echo ""
}

# ════════════════════════════════════════════════════════════
# MODE SELECTION
# ════════════════════════════════════════════════════════════
_select_mode_gum() {
    echo -e "  ${DG}  ─────────────────────────────────────────────────────────────${NC}"
    echo ""

    local choice
    choice=$(gum choose \
        --header="  SELECT AWAKENING PROTOCOL" \
        --header.foreground="2" \
        --cursor.foreground="2" \
        --selected.foreground="2" \
        --item.foreground="8" \
        "  DERMAL LAYER ONLY       //  apply Necrodermis to existing Hyprland" \
        "  FULL CANOPTEK CONVERSION //  complete awakening  ·  packages + configs" \
    2>/dev/null) || choice=""

    case "$choice" in
        *"DERMAL LAYER"*)     MODE="dots" ;;
        *"CANOPTEK"*)         MODE="full" ;;
        *)
            echo -e "\n  ${DG}  No directive received  //  the tomb remains sealed.${NC}\n"
            exit 0
            ;;
    esac
}

_select_mode_tty() {
    echo -e "  ${DG}  ─────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${G}  [1]${NC}  DERMAL LAYER ONLY       //  apply Necrodermis to existing Hyprland"
    echo -e "  ${G}  [2]${NC}  FULL CANOPTEK CONVERSION //  complete awakening  ·  packages + configs"
    echo -e "  ${G}  [q]${NC}  ABORT                   //  the tomb remains sealed"
    echo ""
    echo -ne "  ${DG}  DIRECTIVE ⟩ ${NC}"
    read -r tty_choice

    case "${tty_choice,,}" in
        1) MODE="dots" ;;
        2) MODE="full" ;;
        q|quit|exit|abort|"")
            echo -e "\n  ${DG}  Aborted  //  the tomb remains sealed.${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n  ${R}  Unrecognised directive  //  aborting.${NC}\n"
            exit 1
            ;;
    esac
}

# ════════════════════════════════════════════════════════════
# CONFIRMATION GATE
# ════════════════════════════════════════════════════════════
_confirm_mode() {
    local label=""
    local warning=""

    case "$MODE" in
        dots)
            label="DERMAL LAYER  //  theme-only install"
            warning="Applies Necrodermis configs to an existing Hyprland setup.\nExisting configs will be archived before anything is touched."
            ;;
        full)
            label="FULL CANOPTEK CONVERSION  //  complete awakening"
            warning="Installs all packages and deploys full Necrodermis configuration.\nEstimated time: 10–30 minutes. Do not leave the terminal unattended."
            ;;
    esac

    echo ""
    echo -e "  ${DG}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${G}${B}  PROTOCOL:${NC}  ${label}"
    echo ""
    echo -e "  ${DG}$(echo -e "$warning" | while IFS= read -r l; do echo "  $l"; done)${NC}"
    echo ""

    if [[ "$GUM_AVAILABLE" == true ]]; then
        gum confirm \
            --affirmative="  INITIATE  " \
            --negative="  ABORT     " \
            "  Confirm awakening protocol?" \
        || { echo -e "\n  ${DG}  Aborted  //  the tomb remains sealed.${NC}\n"; exit 0; }
    else
        echo -ne "  ${DG}  Confirm? [y/N] ⟩ ${NC}"
        read -r confirm_choice
        [[ "${confirm_choice,,}" == "y" ]] || {
            echo -e "\n  ${DG}  Aborted  //  the tomb remains sealed.${NC}\n"
            exit 0
        }
    fi
}

# ════════════════════════════════════════════════════════════
# HANDOFF  //  pass mode into install.sh as the correct flag
# ════════════════════════════════════════════════════════════
_handoff() {
    echo ""
    echo -e "  ${DG}  ─────────────────────────────────────────────────────────────${NC}"

    local mode_flag=""
    case "$MODE" in
        dots) mode_flag="--theme-only" ;;
        full) mode_flag="--full"       ;;
    esac

    echo -e "  ${G}  Initiating awakening sequence...${NC}"
    echo -e "  ${DG}  Protocol: ${mode_flag}${NC}"
    echo ""
    sleep 0.5

    exec bash "$INSTALL_SH" "$mode_flag" "${PASSTHROUGH_FLAGS[@]}"
}

# ════════════════════════════════════════════════════════════
# PLATFORM DETECTION + ROUTING
# ════════════════════════════════════════════════════════════
_detect_and_route() {
    # ── macOS — hand off immediately ─────────────────────────────────────────
    if [[ "$(uname)" == "Darwin" ]]; then
        local mac_installer="$SCRIPT_DIR/install_mac.sh"
        if [[ ! -f "$mac_installer" ]]; then
            echo -e "\n  ${R}  ABORT  //  install_mac.sh not found${NC}"
            echo -e "  ${DG}  Expected: ${mac_installer}${NC}\n"
            exit 1
        fi
        echo -e "  ${Y}  macOS substrate detected  //  routing to Dermal Adaptation Protocol${NC}"
        sleep 0.5
        exec bash "$mac_installer" "${PASSTHROUGH_FLAGS[@]}"
    fi

    # ── Linux — check distro support ─────────────────────────────────────────
    local distro
    # Source detect.sh to get detect_distro
    if [[ -f "$SCRIPT_DIR/detect.sh" ]]; then
        source "$SCRIPT_DIR/detect.sh"
    fi
    distro="$(detect_distro 2>/dev/null || echo "unknown")"

    case "$distro" in
        arch|cachyos|manjaro|fedora|opensuse|void)
            # Supported — continue to mode selection
            echo -e "  ${DG}  Substrate:${NC}  ${G}${distro}${NC}"
            return 0
            ;;
        unknown)
            echo ""
            echo -e "  ${R}  ──────────────────────────────────────────────────────────${NC}"
            echo -e "  ${R}  UNSUPPORTED SUBSTRATE DETECTED${NC}"
            echo -e "  ${DG}  NECRODERMIS targets:${NC}"
            echo -e "  ${G}    Arch Linux  ·  CachyOS  ·  Manjaro${NC}"
            echo -e "  ${G}    Fedora 38+  ·  openSUSE Tumbleweed  ·  Void Linux${NC}"
            echo ""
            echo -e "  ${DG}  Debian / Ubuntu / NixOS / Gentoo: not supported.${NC}"
            echo -e "  ${DG}  If you know what you're doing — fork it and port it.${NC}"
            echo -e "  ${R}  ──────────────────────────────────────────────────────────${NC}"
            echo ""

            if command -v gum &>/dev/null && [[ -t 0 ]]; then
                gum confirm \
                    --affirmative="  CONTINUE ANYWAY  " \
                    --negative="  ABORT  " \
                    "  Proceed on unsupported distro?" \
                || { echo -e "\n  ${DG}  Aborted.${NC}\n"; exit 0; }
            else
                echo -ne "  ${DG}  Continue on unsupported distro? [y/N] ⟩ ${NC}"
                read -r _c
                [[ "${_c,,}" != "y" ]] && echo -e "\n  ${DG}  Aborted.${NC}\n" && exit 0
            fi
            ;;
    esac
}


_acquire_gum
_splash
_detect_and_route
 — skip selection, go straight to confirm
if [[ -n "$MODE" ]]; then
    _confirm_mode
    _handoff
fi

# Interactive mode — present menu
if [[ "$GUM_AVAILABLE" == true ]]; then
    _select_mode_gum
else
    _select_mode_tty
fi

_confirm_mode
_handoff
