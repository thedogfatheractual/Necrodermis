#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — ND-RESTORE
# Restore selected configs from git — blows away local changes
# ════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/scripts/common.sh"

print_section "RESTORE PROTOCOL  //  SELECT CONFIGS TO RESURRECT"

# ── Build list of available configs ──────────────────────────────────────────
mapfile -t choices < <(ls "$SCRIPT_DIR/configs/")

# ── Let user pick ─────────────────────────────────────────────────────────────
selected=$(printf '%s\n' "${choices[@]}" | gum choose --no-limit \
    --header "  Space to select, Enter to confirm")

if [ -z "$selected" ]; then
    echo ""
    print_info "Nothing selected — tomb remains unchanged."
    exit 0
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${Y}The following configs will be restored from git:${NC}"
echo "$selected" | while read -r item; do
    echo -e "  ${DG}  //  configs/$item${NC}"
done
echo ""

gum confirm --default=false "  Overwrite selected configs with repo versions?" || {
    print_info "Aborted — no changes made."
    exit 0
}

# ── Restore ───────────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR"
echo "$selected" | while read -r item; do
    necro_run git checkout -- "configs/$item"
    print_ok "Restored  ${DG}//  configs/$item${NC}"
done

print_section "RESTORE COMPLETE  //  SELECTED NODES RESURRECTED"
