#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — CANOPTEK SYNCHRONISATION PROTOCOL
# Update Script — pulls repo and redeploys changed configs
# Do not run install.sh for updates — use this instead
# ════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config/necrodermis-backup-$(date +%Y%m%d-%H%M%S)"

# ── COLOURS ──
G='\033[0;32m'
DG='\033[2;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[1m'
NC='\033[0m'

print_header() {
    clear
    echo ""
    echo -e "${G}${B}"
    echo "  ╔═════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                 ║"
    echo "  ║      CANOPTEK SYNCHRONISATION PROTOCOL — ONLINE                ║"
    echo "  ║      NECRODERMIS // SAUTEKH DYNASTY // UPDATE SEQUENCE         ║"
    echo "  ║                                                                 ║"
    echo "  ╚═════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DG}  SCANNING ENGRAM BANKS FOR DELTA...${NC}"
    echo ""
}

print_section() { echo -e "\n${G}${B}  ╔─────────────────────────────────────────────────────────────╗\n  ║  $1\n  ╚─────────────────────────────────────────────────────────────╝${NC}"; }
print_ok()      { echo -e "  ${G}✓${NC}  $1"; }
print_skip()    { echo -e "  ${Y}·${NC}  $1 ${DG}[no change — dormant]${NC}"; }
print_err()     { echo -e "  ${R}✗${NC}  $1"; }
print_info()    { echo -e "  ${DG}   $1${NC}"; }

# ── DEPLOY — only copies if source is newer or differs ──
deploy() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if [ ! -e "$src" ]; then
        print_err "$label — source missing: $src"
        return 0
    fi

    if [ -e "$dst" ] && diff -rq "$src" "$dst" &>/dev/null; then
        print_skip "$label"
        return 0
    fi

    if [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$dst" "$BACKUP_DIR/$(basename "$dst")"
        print_info "archived  //  $BACKUP_DIR/$(basename "$dst")"
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

# ════════════════════════════════════════════════════════════
print_header

# ── STEP 1 — PULL REPO ──
print_section "RETRIEVING ENGRAM UPDATES FROM TOMB NETWORK"
cd "$SCRIPT_DIR"
git pull
echo ""

# ── STEP 2 — CONFIGS ──
print_section "SYNCHRONISING CONFIGURATION NODES"

deploy "$SCRIPT_DIR/configs/rofi"              "$CONFIG_DIR/rofi"              "rofi"
deploy "$SCRIPT_DIR/configs/hypr/scripts"      "$CONFIG_DIR/hypr/scripts"      "hypr scripts"
deploy "$SCRIPT_DIR/configs/hypr/conf"         "$CONFIG_DIR/hypr/configs"      "hypr conf"
deploy "$SCRIPT_DIR/configs/hypr/user"         "$CONFIG_DIR/hypr/UserConfigs"  "hypr user"
deploy "$SCRIPT_DIR/configs/waybar"            "$CONFIG_DIR/waybar"            "waybar"
deploy "$SCRIPT_DIR/configs/swaync"            "$CONFIG_DIR/swaync"            "swaync"
deploy "$SCRIPT_DIR/configs/kitty"             "$CONFIG_DIR/kitty"             "kitty"
deploy "$SCRIPT_DIR/configs/btop"              "$CONFIG_DIR/btop"              "btop"
deploy "$SCRIPT_DIR/configs/cava"              "$CONFIG_DIR/cava"              "cava"
deploy "$SCRIPT_DIR/configs/fastfetch"         "$CONFIG_DIR/fastfetch"         "fastfetch"
deploy "$SCRIPT_DIR/configs/Kvantum"           "$CONFIG_DIR/Kvantum"           "Kvantum"
deploy "$SCRIPT_DIR/configs/qt5ct"             "$CONFIG_DIR/qt5ct"             "qt5ct"
deploy "$SCRIPT_DIR/configs/qt6ct"             "$CONFIG_DIR/qt6ct"             "qt6ct"
deploy "$SCRIPT_DIR/configs/gtk-3.0"           "$CONFIG_DIR/gtk-3.0"           "gtk-3.0"
deploy "$SCRIPT_DIR/configs/gtk-4.0"           "$CONFIG_DIR/gtk-4.0"           "gtk-4.0"
deploy "$SCRIPT_DIR/configs/wlogout"           "$CONFIG_DIR/wlogout"           "wlogout"
deploy "$SCRIPT_DIR/configs/wallust"           "$CONFIG_DIR/wallust"           "wallust"

# ── STEP 3 — FISH CONFIG ──
print_section "FISH SHELL — ENGRAM SYNCHRONISATION"
FISH_CONF="$CONFIG_DIR/fish/config.fish"
REPO_FISH="$SCRIPT_DIR/configs/fish/config.fish"
if [ -f "$REPO_FISH" ]; then
    deploy "$REPO_FISH" "$FISH_CONF" "fish config"
fi

# ── STEP 4 — HYPR SCRIPTS PERMISSIONS ──
print_section "RESTORING SCRIPT PERMISSIONS"
if [ -d "$CONFIG_DIR/hypr/scripts" ]; then
    chmod +x "$CONFIG_DIR/hypr/scripts"/*.sh 2>/dev/null && print_ok "hypr scripts  ${DG}//  permissions restored${NC}" || true
fi
if [ -d "$CONFIG_DIR/hypr/user-scripts" ]; then
    chmod +x "$CONFIG_DIR/hypr/user-scripts"/*.sh 2>/dev/null && print_ok "hypr user-scripts  ${DG}//  permissions restored${NC}" || true
fi

# ── DONE ──
echo ""
echo -e "${G}${B}  ════════════════════════════════════════════════════════════${NC}"
echo -e "${G}${B}  SYNCHRONISATION COMPLETE  //  CANOPTEK ARRAY STANDING DOWN${NC}"
echo -e "${G}${B}  ════════════════════════════════════════════════════════════${NC}"
echo ""
