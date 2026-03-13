#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — COMMON UTILITIES
# Sourced by install.sh — do not run directly
# ════════════════════════════════════════════════════════════

# ── COLOURS ──
G='\033[0;32m'
DG='\033[2;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[1m'
NC='\033[0m'

# ── GUM THEME — NECRODERMIS PALETTE ──
export GUM_CONFIRM_PROMPT_FOREGROUND="2"
export GUM_CONFIRM_SELECTED_FOREGROUND="0"
export GUM_CONFIRM_SELECTED_BACKGROUND="2"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="8"
export GUM_INPUT_CURSOR_FOREGROUND="2"
export GUM_INPUT_PROMPT_FOREGROUND="2"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="8"
export GUM_CHOOSE_CURSOR_FOREGROUND="2"
export GUM_CHOOSE_SELECTED_FOREGROUND="2"
export GUM_CHOOSE_ITEM_FOREGROUND="7"
export GUM_CHOOSE_HEADER_FOREGROUND="2"

# ── PRINT FUNCTIONS ──
print_header() {
    clear
    echo ""
    echo -e "${G}${B}"
    echo "  ╔═════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                 ║"
    echo "  ║          ███╗   ██╗███████╗ ██████╗██████╗  ██████╗             ║"
    echo "  ║          ████╗  ██║██╔════╝██╔════╝██╔══██╗██╔═══██╗            ║"
    echo "  ║          ██╔██╗ ██║█████╗  ██║     ██████╔╝██║   ██║            ║"
    echo "  ║          ██║╚██╗██║██╔══╝  ██║     ██╔══██╗██║   ██║            ║"
    echo "  ║          ██║ ╚████║███████╗╚██████╗██║  ██║╚██████╔╝            ║"
    echo "  ║          ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝             ║"
    echo "  ║                                                                 ║"
    echo "  ║          ~~   NECRODERMIS   ~~            ║"
    local _ver; _ver=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "?.?.?")
    echo "  ║       ~~   AWAKENING PROTOCOL INITIATED // v${_ver}   ~~          ║"
    echo "  ║                                                                 ║"
    echo "  ╚═════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DG}  STASIS DURATION: 60,247,891 YRS  //  47 MAINTENANCE FAULTS UNRESOLVED${NC}"
    echo -e "${DG}  LAST DIAGNOSTIC: 4,891 YEARS AGO  //  TOMB INTEGRITY BREACH DETECTED${NC}"
    echo -e "${DG}  CANOPTEK SCARABS: DEPLOYED  //  RESURRECTION PROTOCOLS: ONLINE${NC}"
    echo ""
    [ "$NECRO_DEBUG" -eq 1 ] && echo -e "  ${Y}${B}  ⚠  DEBUG MODE ACTIVE — NO CHANGES WILL BE WRITTEN  ⚠${NC}"
    echo ""
}

print_credit() {
    clear
    echo ""
    echo -e "${G}${B}"
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                   ATTRIBUTION PROTOCOL                          ║"
    echo "  ║             THE DYNASTY HONOURS THOSE WHO CAME BEFORE           ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DG}  Necrodermis is built on the shoulders of the Hyprland community.${NC}"
    echo -e "${DG}  Full attribution in README.md — the Dynasty honours its debts.${NC}"
    echo ""
    echo -e "${B}  ── thedogfatheractual — Necrodermis ──${NC}"
    echo -e "${G}  https://github.com/thedogfatheractual/Necrodermis${NC}"
    echo ""
    echo -e "${DG}  ════════════════════════════════════════════════════════════${NC}"
    echo -e "${DG}  ORGANIC MATTER IS TEMPORARY  //  NECRODERMIS IS ETERNAL${NC}"
    echo -e "${DG}  ════════════════════════════════════════════════════════════${NC}"
    echo ""
    gum confirm --default=true \
        --affirmative="  INITIATE AWAKENING  " \
        --negative="  ABORT  " \
        "  PRESS ENTER TO INITIATE AWAKENING SEQUENCE" || {
        echo -e "\n  ${DG}  The tomb remains sealed.${NC}\n"
        exit 0
    }
}

print_section() {
    echo ""
    echo -e "${G}${B}  ╔─────────────────────────────────────────────────────────────╗${NC}"
    echo -e "${G}${B}  ║  $1${NC}"
    echo -e "${G}${B}  ╚─────────────────────────────────────────────────────────────╝${NC}"
}

print_ok()   { echo -e "  ${G}✓${NC}  $1"; }
print_skip() { echo -e "  ${Y}·${NC}  $1 ${DG}[dormant — skipped]${NC}"; }
print_err()  { echo -e "  ${R}✗${NC}  $1"; }
print_info() { echo -e "  ${DG}   $1${NC}"; }

# ── INTERACTIVE PROMPTS ──
ask() {
    echo ""
    gum confirm --default=true "  Install $1?"
}

confirm() {
    gum confirm --default=true "  $1"
}

ask_no() {
    echo ""
    gum confirm --default=false "  $1?"
}

# ── NECRO_RUN — DEBUG-AWARE EXECUTOR ──
necro_run() {
    if [ "$NECRO_DEBUG" -eq 1 ]; then
        local cmd="$*"
        local destructive=0
        [[ "$cmd" =~ (rm|mv|cp|chmod|chown|tee|install|systemctl\ enable|systemctl\ start|pacman|yay|paru) ]] && destructive=1
        if [ "$destructive" -eq 1 ]; then
            echo -e "  ${Y}⚠  [DEBUG] WOULD RUN:${NC} $cmd"
        else
            echo -e "  ${DG}   [DEBUG] WOULD RUN:${NC} $cmd"
        fi
        return 0
    fi
    "$@"
}

# ── BACKUP AND INSTALL ──
backup_and_install() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if [ ! -e "$src" ]; then
        print_err "$label — source node missing: $src"
        return 1
    fi

    if [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        local link_target
        link_target=$(readlink -f "$dst")
        if [ -e "$link_target" ]; then
            cp -r "$link_target" "$BACKUP_DIR/$(basename "$dst")"
            print_info "symlink target archived  //  $link_target"
        fi
        rm "$dst"
        print_info "symlink severed  //  $dst"
    elif [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$dst" "$BACKUP_DIR/$(basename "$dst")"
        print_info "previous configuration archived"
    fi

    if [ -d "$src" ]; then
        mkdir -p "$dst"
        cp -r "$src/." "$dst/"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    fi
    print_ok "$label  ${DG}//  NODE SYNCHRONISED${NC}"
}

# ── BUNDLE UNINSTALLER ──
bundle_uninstaller() {
    print_section "UNINSTALLER  //  DEPLOYING DEACTIVATION PROTOCOL"

    mkdir -p "$NECRO_HOME"
    mkdir -p "$NECRO_BIN"

    cp "$SCRIPT_DIR/install.sh" "$NECRO_HOME/install.sh"
    cp "$SCRIPT_DIR/uninstall.sh" "$NECRO_HOME/uninstall.sh"
    chmod +x "$NECRO_HOME/install.sh"
    chmod +x "$NECRO_HOME/uninstall.sh"

    cat > "$NECRO_BIN/necrodermis-uninstall" <<'WRAPPER'
#!/usr/bin/env bash
NECRO_HOME="$HOME/.local/share/necrodermis"
if [ ! -f "$NECRO_HOME/uninstall.sh" ]; then
    echo ""
    echo "  ERROR: Necrodermis uninstaller not found at:"
    echo "  $NECRO_HOME/uninstall.sh"
    echo ""
    exit 1
fi
bash "$NECRO_HOME/uninstall.sh"
WRAPPER

    chmod +x "$NECRO_BIN/necrodermis-uninstall"

    if ! echo "$PATH" | grep -q "$NECRO_BIN"; then
        if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
            if ! grep -q "necrodermis" "$CONFIG_DIR/fish/config.fish"; then
                echo "" >> "$CONFIG_DIR/fish/config.fish"
                echo "# Necrodermis" >> "$CONFIG_DIR/fish/config.fish"
                echo "fish_add_path $NECRO_BIN" >> "$CONFIG_DIR/fish/config.fish"
            fi
        fi
        if [ -f "$HOME/.bashrc" ]; then
            if ! grep -q "$NECRO_BIN" "$HOME/.bashrc"; then
                echo "" >> "$HOME/.bashrc"
                echo "# Necrodermis" >> "$HOME/.bashrc"
                echo "export PATH=\"$NECRO_BIN:\$PATH\"" >> "$HOME/.bashrc"
            fi
        fi
        if [ -f "$HOME/.zshrc" ]; then
            if ! grep -q "$NECRO_BIN" "$HOME/.zshrc"; then
                echo "" >> "$HOME/.zshrc"
                echo "# Necrodermis" >> "$HOME/.zshrc"
                echo "export PATH=\"$NECRO_BIN:\$PATH\"" >> "$HOME/.zshrc"
            fi
        fi
    fi

    print_ok "Uninstaller deployed  ${DG}//  $NECRO_HOME/uninstall.sh${NC}"
    print_ok "Command registered    ${DG}//  necrodermis-uninstall${NC}"
}

# ── NECRO_PRINT — LABELED COMPONENT MESSAGE ──
# Usage: necro_print "component" "message"
necro_print() {
    local label="$1"
    local msg="$2"
    echo -e "  ${G}[${label}]${NC}  $msg"
}

# ── NECRO_BACKUP — STANDALONE DIRECTORY BACKUP ──
# Usage: necro_backup "/path/to/dir"
# Archives target to BACKUP_DIR — no install, just archive
necro_backup() {
    local target="$1"
    if [ -e "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        local name
        name="$(basename "$target")_$(date +%Y%m%d_%H%M%S)"
        cp -r "$target" "$BACKUP_DIR/$name"
        print_info "archived  //  $BACKUP_DIR/$name"
    fi
}
source "$SCRIPT_DIR/scripts/common_triage.sh"
