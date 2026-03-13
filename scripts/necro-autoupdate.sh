#!/usr/bin/env bash
# NECRODERMIS — necro-autoupdate.sh
# Canoptek Update Relay — dials the tomb world for new directives

NECRO_REPO="$HOME/.local/share/necrodermis/repo"
NECRO_BACKUP_DIR="$HOME/.local/share/necrodermis/update-backups/$(date +%Y%m%d-%H%M%S)"
NECRO_REMOTE="https://github.com/thedogfatheractual/Necrodermis"

G='\033[0;32m'
DG='\033[2;32m'
B='\033[1m'
Y='\033[0;33m'
R='\033[0;31m'
NC='\033[0m'

_header() {
    echo ""
    echo -e "${G}${B}  ══════════════════════════════════════════════════${NC}"
    echo -e "${G}${B}  CANOPTEK UPDATE RELAY  //  NECRODERMIS${NC}"
    echo -e "${G}${B}  ══════════════════════════════════════════════════${NC}"
    echo ""
}

_section() {
    echo ""
    echo -e "${G}  ── $1 ──────────────────────────────${NC}"
    echo ""
}

_info()  { echo -e "${DG}  ·  $1${NC}"; }
_ok()    { echo -e "${G}  ✓  $1${NC}"; }
_warn()  { echo -e "${Y}  ⚠  $1${NC}"; }
_err()   { echo -e "${R}  ✗  $1${NC}"; }

_header

# ── PHASE 1 — SYSTEM PACKAGE SYNC ────────────────────────────────────────────
_section "PHASE I  //  SYNCHRONISING TOMB WORLD PACKAGE REGISTRY"
_info "Dispatching Canoptek scarabs to the AUR..."
_info "This may take several minutes — tomb maintenance in progress."
echo ""

if command -v yay &>/dev/null; then
    yay -Syyu --noconfirm
    _ok "Package registry synchronised  //  all dynasties updated"
elif command -v paru &>/dev/null; then
    paru -Syyu --noconfirm
    _ok "Package registry synchronised  //  all dynasties updated"
else
    _warn "No AUR helper found  //  skipping package sync"
fi

# ── PHASE 2 — NECRODERMIS CONFIG RELAY ───────────────────────────────────────
_section "PHASE II  //  DIALLING TOMB WORLD CONFIG RELAY"
_info "Establishing uplink to github.com/thedogfatheractual/Necrodermis..."

# Clone repo to temp if not already cached
NECRO_TMP=$(mktemp -d)
trap "rm -rf $NECRO_TMP" EXIT

if ! git clone --depth=1 "$NECRO_REMOTE" "$NECRO_TMP" &>/dev/null; then
    _err "Uplink failed  //  tomb world unreachable"
    _info "Check your connection — config sync skipped"
    exit 1
fi

_ok "Uplink established  //  remote tomb world responding"

# ── PHASE 3 — DIFF CONFIGS ────────────────────────────────────────────────────
_section "PHASE III  //  SCANNING FOR CANOPTEK DIRECTIVES"
_info "Comparing local dermal layer against remote tomb world..."

CHANGED_FILES=()
CONFIG_SRC="$NECRO_TMP/configs"

while IFS= read -r -d '' remote_file; do
    rel_path="${remote_file#$CONFIG_SRC/}"
    local_file="$HOME/.config/$rel_path"

    if [[ -f "$local_file" ]]; then
        if ! diff -q "$remote_file" "$local_file" &>/dev/null; then
            CHANGED_FILES+=("$rel_path")
            _warn "Updated directive detected  //  $rel_path"
        fi
    else
        CHANGED_FILES+=("$rel_path")
        _info "New directive detected  //  $rel_path"
    fi
done < <(find "$CONFIG_SRC" -type f -print0)

if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
    _ok "Dermal layer is current  //  no tomb world updates detected"
    echo ""
    echo -e "${G}${B}  CANOPTEK RELAY COMPLETE  //  ALL SYSTEMS NOMINAL${NC}"
    echo ""
    exit 0
fi

echo ""
_info "${#CHANGED_FILES[@]} updated directive(s) available from the tomb world"

# ── PHASE 4 — OFFER CHOICE ───────────────────────────────────────────────────
_section "PHASE IV  //  AWAITING OPERATOR DIRECTIVE"
echo -e "${Y}  The following files differ from the remote tomb world:${NC}"
echo ""
for f in "${CHANGED_FILES[@]}"; do
    echo -e "${DG}    ·  $f${NC}"
done
echo ""

if command -v gum &>/dev/null; then
    CHOICE=$(gum choose \
        --header="  Deploy updated directives from tomb world?" \
        --header.foreground="2" \
        --cursor.foreground="2" \
        --item.foreground="7" \
        "  YES — backup existing and deploy updates" \
        "  NO  — ignore for now")
else
    echo -e "${Y}  Deploy updates? [y/N]:${NC} "
    read -r CHOICE
    [[ "$CHOICE" =~ ^[Yy]$ ]] && CHOICE="YES" || CHOICE="NO"
fi

if [[ "$CHOICE" != *"YES"* ]]; then
    _info "Operator dismissed update  //  tomb world directives ignored"
    echo ""
    echo -e "${G}${B}  CANOPTEK RELAY COMPLETE  //  STANDING BY${NC}"
    echo ""
    exit 0
fi

# ── PHASE 5 — BACKUP AND DEPLOY ──────────────────────────────────────────────
_section "PHASE V  //  DEPLOYING TOMB WORLD DIRECTIVES"
mkdir -p "$NECRO_BACKUP_DIR"
_info "Archiving existing dermal layer  //  $NECRO_BACKUP_DIR"

for f in "${CHANGED_FILES[@]}"; do
    local_file="$HOME/.config/$f"
    if [[ -f "$local_file" ]]; then
        backup_dest="$NECRO_BACKUP_DIR/$f"
        mkdir -p "$(dirname "$backup_dest")"
        cp "$local_file" "$backup_dest"
        _info "Archived  //  $f"
    fi

    remote_file="$CONFIG_SRC/$f"
    dest="$HOME/.config/$f"
    mkdir -p "$(dirname "$dest")"
    cp "$remote_file" "$dest"
    _ok "Deployed  //  $f"
done

echo ""
_ok "Tomb world directives deployed  //  ${#CHANGED_FILES[@]} file(s) updated"
_info "Backups archived at  //  $NECRO_BACKUP_DIR"
echo ""
echo -e "${G}${B}  CANOPTEK RELAY COMPLETE  //  THE DYNASTY ENDURES${NC}"
echo ""
