#!/usr/bin/env bash
# NECRODERMIS — install_mac.sh
# macOS Homebrew scaffold — mirrors install.sh patterns
# Invoked by necro-launch.sh on Darwin detection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
NECRO_VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo 'unknown')"

# ── Colours ──
DG='\033[0;32m'; R='\033[0;31m'; Y='\033[0;33m'; W='\033[1;37m'
DIM='\033[2m'; NC='\033[0m'

print_section() { echo -e "\n${DG}  ══  ${W}${1}${NC}"; }
print_ok()      { echo -e "  ${DG}[  OK  ]${NC}  ${1}"; }
print_info()    { echo -e "  ${DG}[ INFO ]${NC}  ${1}"; }
print_err()     { echo -e "  ${R}[ FAIL ]${NC}  ${1}" >&2; }
print_warn()    { echo -e "  ${Y}[ WARN ]${NC}  ${1}"; }

# ── Homebrew check ──
check_brew() {
    if ! command -v brew &>/dev/null; then
        print_info "Homebrew not found — installing"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print_ok "Homebrew present"
    fi
}

# ── Package dispatcher ──
brew_pkg() {
    local label="$1"
    local pkg="$2"
    print_info "Installing $label"
    brew install "$pkg" 2>/dev/null || print_warn "$label already present or unavailable"
}

brew_cask() {
    local label="$1"
    local pkg="$2"
    print_info "Installing $label (cask)"
    brew install --cask "$pkg" 2>/dev/null || print_warn "$label already present or unavailable"
}

# ── Install dotfiles ──
install_dotfiles_mac() {
    print_section "DOTFILES  //  DERMAL LAYER APPLICATION"

    local targets=(
        "configs/fish:$CONFIG_DIR/fish"
        "configs/kitty:$CONFIG_DIR/kitty"
        "configs/fastfetch:$CONFIG_DIR/fastfetch"
        "configs/btop:$CONFIG_DIR/btop"
    )

    for entry in "${targets[@]}"; do
        local src="${entry%%:*}"
        local dst="${entry##*:}"
        if [[ -d "$SCRIPT_DIR/$src" ]]; then
            mkdir -p "$(dirname "$dst")"
            cp -r "$SCRIPT_DIR/$src" "$dst"
            print_ok "$src applied"
        else
            print_warn "$src not found — skipping"
        fi
    done
}

# ── Core packages ──
install_core_mac() {
    print_section "CORE PACKAGES  //  CANOPTEK SUBSTRATE"
    brew_pkg "fish"      "fish"
    brew_pkg "kitty"     "kitty"
    brew_pkg "neovim"    "neovim"
    brew_pkg "btop"      "btop"
    brew_pkg "fastfetch" "fastfetch"
    brew_pkg "git"       "git"
    brew_pkg "python3"   "python3"
    brew_pkg "gum"       "gum"
    brew_pkg "jq"        "jq"

    # Set fish as default shell
    if ! grep -q "$(brew --prefix)/bin/fish" /etc/shells 2>/dev/null; then
        echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
    fi
    chsh -s "$(brew --prefix)/bin/fish" 2>/dev/null || print_warn "Could not set fish as default shell — do it manually"
}

# ── Extras ──
install_extras_mac() {
    print_section "EXTRAS  //  OPTIONAL ACQUISITIONS"
    brew_cask "Brave Browser" "brave-browser"
    brew_pkg  "sitrep deps"   "python3"
}

# ── Sitrep ──
install_sitrep_mac() {
    print_section "SITREP  //  ATMOSPHERIC INTELLIGENCE"
    local SITREP_ROOT="$HOME/.local/share/sitrep_install"

    if [[ -f "$HOME/.local/bin/sitrep" ]]; then
        print_ok "Sitrep already installed — skipping"
        return 0
    fi

    mkdir -p "$SITREP_ROOT"
    python3 -m venv "$SITREP_ROOT/venv"
    "$SITREP_ROOT/venv/bin/pip" install --quiet "requests>=2.28" "tzlocal>=4.0"

    local tmp
    tmp=$(mktemp -d)
    if git clone --depth=1 "https://github.com/thedogfatheractual/sitrep.git" "$tmp/sitrep" 2>/dev/null; then
        bash "$tmp/sitrep/install_sitrep_full.sh"
        print_ok "Sitrep installed"
    else
        print_err "Sitrep clone failed — network required"
    fi
    rm -rf "$tmp"
}

# ── Codex ──
run_codex() {
    [[ -f "$SCRIPT_DIR/scripts/necro-codex.sh" ]] && bash "$SCRIPT_DIR/scripts/necro-codex.sh"
}

# ── Main ──
main() {
    clear
    echo -e "${DG}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  NECRODERMIS  //  macOS CONVERSION SEQUENCE         ║"
    echo "  ║  $NECRO_VERSION                                            ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_brew
    install_core_mac
    install_dotfiles_mac
    install_extras_mac
    install_sitrep_mac
    run_codex
}

main "$@"
