#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# SPASSKAYA CLOCKS — CLOCKTOWER CHIME INSTALLER
# https://github.com/thedogfatheractual/spasskaya-clocks
# ════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/.local/share/spasskaya-clocks"
CONFIG_FILE="$APP_DIR/active-chime"
PLAYBACK_SCRIPT="$APP_DIR/playback.sh"
SOUNDS_DIR="$SCRIPT_DIR/sounds"

G='\033[0;32m'
DG='\033[2;32m'
Y='\033[0;33m'
R='\033[0;31m'
B='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${G}  ✓  $1${NC}"; }
log_warn()  { echo -e "${Y}  ·  $1${NC}"; }
log_error() { echo -e "${R}  ✗  $1${NC}" >&2; exit 1; }

# ── Dependency check ─────────────────────────────────────────
check_dependencies() {
    echo ""
    echo -e "${G}${B}  Checking dependencies...${NC}"
    command -v ffplay  >/dev/null || log_error "ffplay not found — install ffmpeg (pacman -S ffmpeg)"
    command -v crontab >/dev/null || log_error "crontab not found — install cronie (pacman -S cronie)"
    command -v gum     >/dev/null || log_error "gum not found — install gum (yay -S gum)"
    log_info "Dependencies met."
}

# ── Detect available sound packs ─────────────────────────────
detect_sound_packs() {
    local packs=()
    if [[ -d "$SOUNDS_DIR" ]]; then
        for dir in "$SOUNDS_DIR"/*/; do
            [[ -f "${dir}half.flac" && -f "${dir}full.flac" && -f "${dir}single.flac" ]] \
                && packs+=("$(basename "$dir")")
        done
    fi
    echo "${packs[@]:-}"
}

# ── Chime selector ────────────────────────────────────────────
select_chime_pack() {
    local packs=()
    read -ra packs <<< "$(detect_sound_packs)"

    if (( ${#packs[@]} == 0 )); then
        log_error "No valid sound packs found in $SOUNDS_DIR — each pack needs half.flac, full.flac, single.flac"
    fi

    if (( ${#packs[@]} == 1 )); then
        SELECTED_PACK="${packs[0]}"
        log_info "One sound pack found — using: ${SELECTED_PACK}"
        return
    fi

    echo ""
    echo -e "${G}${B}  Available chime packs:${NC}"
    echo ""

    SELECTED_PACK=$(
        printf '%s\n' "${packs[@]}" | \
        gum choose \
            --header="  Select your chime pack" \
            --header.foreground="2" \
            --cursor.foreground="2" \
            --selected.foreground="2" \
            --item.foreground="7" \
        2>/dev/null
    ) || log_error "No chime pack selected."

    log_info "Selected: ${SELECTED_PACK}"
}

# ── Install ───────────────────────────────────────────────────
do_install() {
    echo ""
    echo -e "${G}${B}  Installing Spasskaya Clocks...${NC}"
    echo ""

    mkdir -p "$APP_DIR"

    # Copy selected sound pack
    local pack_src="$SOUNDS_DIR/$SELECTED_PACK"
    mkdir -p "$APP_DIR/sounds/$SELECTED_PACK"
    cp "$pack_src/half.flac"   "$APP_DIR/sounds/$SELECTED_PACK/"
    cp "$pack_src/full.flac"   "$APP_DIR/sounds/$SELECTED_PACK/"
    cp "$pack_src/single.flac" "$APP_DIR/sounds/$SELECTED_PACK/"
    log_info "Sound pack installed: $SELECTED_PACK"

    # Write active chime config
    echo "$SELECTED_PACK" > "$CONFIG_FILE"
    log_info "Active chime set to: $SELECTED_PACK"

    # Install playback script
    cp "$SCRIPT_DIR/playback.sh" "$PLAYBACK_SCRIPT"
    chmod +x "$PLAYBACK_SCRIPT"
    log_info "Playback script installed."

    # Set up cron — remove any existing spasskaya entries first
    local tmp_cron
    tmp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "spasskaya-clocks" > "$tmp_cron" || true
    {
        cat "$tmp_cron"
        echo "30 * * * * $PLAYBACK_SCRIPT half   # spasskaya-clocks half-hour chime"
        echo "0  * * * * $PLAYBACK_SCRIPT hourly # spasskaya-clocks hourly chime"
    } | crontab -
    rm -f "$tmp_cron"
    log_info "Cron jobs installed (deduped)."
}

# ── Uninstall ─────────────────────────────────────────────────
do_uninstall() {
    echo ""
    echo -e "${Y}${B}  Uninstalling Spasskaya Clocks...${NC}"
    echo ""

    # Remove cron entries
    crontab -l 2>/dev/null | grep -v "spasskaya-clocks" | crontab - || true
    log_info "Cron jobs removed."

    # Remove app directory
    rm -rf "$APP_DIR"
    log_info "Application files removed."

    echo ""
    echo -e "${G}${B}  Uninstall complete. The tower is silent.${NC}"
    echo ""
    exit 0
}

# ── Entry point ───────────────────────────────────────────────
clear
echo ""
echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${G}${B}  ║   SPASSKAYA CLOCKS  //  CLOCKTOWER CHIME SYSTEM             ║${NC}"
echo -e "${G}${B}  ║   https://github.com/thedogfatheractual/spasskaya-clocks     ║${NC}"
echo -e "${G}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Uninstall flag
if [[ "${1:-}" == "--uninstall" ]]; then
    do_uninstall
fi

check_dependencies
select_chime_pack
do_install

echo ""
echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${G}${B}  ║   INSTALLATION COMPLETE                                      ║${NC}"
echo -e "${G}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${DG}  Active pack:  ${G}${SELECTED_PACK}${NC}"
echo -e "${DG}  Test half:    ${G}$PLAYBACK_SCRIPT half${NC}"
echo -e "${DG}  Test hourly:  ${G}$PLAYBACK_SCRIPT hourly${NC}"
echo -e "${DG}  Uninstall:    ${G}bash install.sh --uninstall${NC}"
echo -e "${DG}  Cron jobs:    ${G}crontab -l${NC}"
echo ""
