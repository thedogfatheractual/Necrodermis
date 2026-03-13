#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/hypr.sh
# Component: install_hypr

install_hypr() {
    print_section "HYPRLAND  //  ENVIRONMENTAL CONTROL MATRIX"

    local HYPR_SRC="$SCRIPT_DIR/configs/hypr"
    local HYPR_DEST="$CONFIG_DIR/hypr"

    necro_print "hypr" "Deploying Hyprland configuration..."

    # ── Backup existing hypr config ───────────────────────────────────────────
    if [ -d "$HYPR_DEST" ] && [ ! -L "$HYPR_DEST" ]; then
        necro_backup "$HYPR_DEST"
    fi

    # ── Symlink entire hypr config directory ──────────────────────────────────
    if [ -L "$HYPR_DEST" ]; then
        rm "$HYPR_DEST"
    fi

    necro_run ln -sf "$HYPR_SRC" "$HYPR_DEST"

    necro_print "hypr" "Hyprland configuration linked — editing ~/.config/hypr edits the repo."
}

    # Touchpad keybind — only wire if touchpad detected
    local TOUCHPAD
    TOUCHPAD=$(libinput list-devices 2>/dev/null | grep -i "touchpad" | head -1)
    local KEYBIND_LINE="bind = \$mainMod, F7, exec, bash \$HOME/.config/hypr/scripts/touchpad-toggle.sh"
    if [[ -n "$TOUCHPAD" ]]; then
        echo "" >> "$CONFIG_DIR/hypr/user/keybinds.conf"
        echo "# Touchpad toggle — detected at install time" >> "$CONFIG_DIR/hypr/user/keybinds.conf"
        echo "$KEYBIND_LINE" >> "$CONFIG_DIR/hypr/user/keybinds.conf"
        print_ok "Touchpad detected  ${DG}//  keybind wired: SUPER+F7${NC}"
    else
        echo "" >> "$CONFIG_DIR/hypr/user/keybinds.conf"
        echo "# Touchpad toggle — no touchpad detected, uncomment if needed" >> "$CONFIG_DIR/hypr/user/keybinds.conf"
        echo "# $KEYBIND_LINE" >> "$CONFIG_DIR/hypr/user/keybinds.conf"
        print_info "No touchpad detected  ${DG}//  keybind commented in user/keybinds.conf${NC}"
    fi
