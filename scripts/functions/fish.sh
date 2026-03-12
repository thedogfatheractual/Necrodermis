#!/usr/bin/env bash
# Necrodermis — scripts/functions/fish.sh
# Component: install_fish

install_fish() {
    print_section "FISH  //  SHELL INTERFACE NODE"

    necro_pkg "fish" fish

    # Set fish as default shell if not already
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v fish)" ]]; then
        print_info "Setting fish as default shell..."
        local fish_path
        fish_path="$(command -v fish)"
        # Ensure fish is in /etc/shells
        if ! grep -qx "$fish_path" /etc/shells; then
            echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
        fi
        sudo chsh -s "$fish_path" "$USER" \
            || necro_log "FAIL" "fish" "chsh failed — set shell manually: chsh -s $fish_path"
        print_ok "fish  ${DG}//  set as default shell — takes effect after next login${NC}"
    else
        print_info "fish already default shell  //  skipping chsh"
    fi

    local SRC="$SCRIPT_DIR/configs/fish"
    local DEST="$CONFIG_DIR/fish"

    necro_print "fish" "Deploying configuration..."

    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        necro_backup "$DEST"
    fi

    if [ -L "$DEST" ]; then
        rm "$DEST"
    fi

    necro_run mkdir -p "$DEST"
    necro_run cp -r "$SRC/." "$DEST/"

    necro_print "fish" "Deployed — user-owned, not symlinked."
}
