#!/usr/bin/env bash
# Necrodermis — scripts/functions/fish.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_fish

install_fish() {
    print_section "FISH  //  COMMAND SHELL INTERFACE"
    backup_and_install "$SCRIPT_DIR/configs/fish/config.fish" \
        "$CONFIG_DIR/fish/config.fish" "shell interface config"

    # Fastfetch autostart — fire manifest on every new terminal
    if ! grep -q "fastfetch" "$CONFIG_DIR/fish/config.fish" 2>/dev/null; then
        echo "" >> "$CONFIG_DIR/fish/config.fish"
        echo "# Necrodermis — system manifest on terminal launch" >> "$CONFIG_DIR/fish/config.fish"
        echo "fastfetch" >> "$CONFIG_DIR/fish/config.fish"
        print_ok "Fastfetch autostart armed  ${DG}//  manifest fires on terminal launch${NC}"
    else
        print_info "fastfetch already in config.fish  //  skipping"
    fi

    # Logout alias — hyprctl dispatch exit
    if ! grep -q "alias logout" "$CONFIG_DIR/fish/config.fish" 2>/dev/null; then
        echo "" >> "$CONFIG_DIR/fish/config.fish"
        echo "# Necrodermis — logout alias" >> "$CONFIG_DIR/fish/config.fish"
        echo "alias logout='hyprctl dispatch exit'" >> "$CONFIG_DIR/fish/config.fish"
        print_ok "logout alias registered  ${DG}//  hyprctl dispatch exit${NC}"
    else
        print_info "logout alias already present  //  skipping"
    fi
}
