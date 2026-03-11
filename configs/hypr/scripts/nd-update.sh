#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — ND-UPDATE
# System update and cleanup utility
# Usage: nd-update.sh [--update|--clean|--both]
# ════════════════════════════════════════════════════════════

set -euo pipefail

G='\033[0;32m'
DG='\033[2;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[1m'
NC='\033[0m'

print_ok()   { echo -e "  ${G}✓${NC}  $1"; }
print_err()  { echo -e "  ${R}✗${NC}  $1"; }
print_info() { echo -e "  ${DG}   $1${NC}"; }

do_update() {
    echo -e "\n${G}${B}  ── SYSTEM UPDATE ──────────────────────────────────${NC}\n"
    yay -Syu --noconfirm
    print_ok "System updated"
}

do_clean() {
    echo -e "\n${G}${B}  ── SYSTEM CLEAN ───────────────────────────────────${NC}\n"

    # Remove orphans
    orphans=$(yay -Qdtq 2>/dev/null)
    if [ -n "$orphans" ]; then
        echo "$orphans" | xargs yay -Rns --noconfirm
        print_ok "Orphans removed"
    else
        print_info "No orphans found"
    fi

    # Clear package cache
    yay -Sc --noconfirm
    print_ok "Package cache cleared"

    # Clear user cache
    rm -rf ~/.cache/yay
    print_ok "yay cache cleared"
}

case "${1:---both}" in
    --update) do_update ;;
    --clean)  do_clean ;;
    --both)   do_update && do_clean ;;
    *)
        echo -e "  ${R}Unknown flag: $1${NC}"
        echo -e "  Usage: nd-update.sh [--update|--clean|--both]"
        exit 1
        ;;
esac

echo -e "\n${G}${B}  ── COMPLETE ────────────────────────────────────────${NC}\n"

