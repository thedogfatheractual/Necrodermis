#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — ND-DEPLOY
# Deploys configs to ~/.config — no package installation
# Safe to run on updates or second machines
# ════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backups/necrodermis-$(date +%Y%m%d_%H%M%S)"
NECRO_DEBUG="${NECRO_DEBUG:-0}"

# ── Source common utilities ───────────────────────────────────────────────────
source "$SCRIPT_DIR/scripts/common.sh"

# ── Source all function files ─────────────────────────────────────────────────
for f in "$SCRIPT_DIR"/scripts/functions/*.sh; do
    source "$f"
done

# ── Deploy ────────────────────────────────────────────────────────────────────
print_header

print_section "DEPLOYMENT PROTOCOL  //  INITIATING CONFIG SYNCHRONISATION"

install_hypr
install_waybar
install_rofi
install_swaync
install_wlogout
install_kitty
install_fish
install_btop
install_cava
install_fastfetch
install_qt

print_section "DEPLOYMENT COMPLETE  //  ALL NODES SYNCHRONISED"
