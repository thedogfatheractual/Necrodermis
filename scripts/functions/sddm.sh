#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/sddm.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_sddm

install_sddm() {
    print_section "SDDM  //  TOMB WORLD AWAKENING INTERFACE"

    local AUR_HELPER
    AUR_HELPER="$(get_aur_helper)"

    # Ensure sddm is installed
    if ! command -v sddm &>/dev/null; then
        sudo pacman -S --needed sddm --noconfirm
    fi

    # Base theme: sddm-astronaut-theme — fully Qt5/Qt6 compatible, all components present
    if [ ! -d "/usr/share/sddm/themes/sddm-astronaut-theme" ]; then
        if [ -n "$AUR_HELPER" ]; then
            print_info "Base theme not found  //  acquiring sddm-astronaut-theme from AUR..."
            $AUR_HELPER -S --needed sddm-astronaut-theme
        else
            print_err "sddm-astronaut-theme not found and no AUR helper available"
            print_info "Install manually: yay -S sddm-astronaut-theme"
            return 1
        fi
    fi

    local THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"

    # Deploy Necrodermis QML overrides
    sudo mkdir -p "$THEME_DIR/Components"
    sudo mkdir -p "$THEME_DIR/Backgrounds"
    sudo mkdir -p "$THEME_DIR/Themes"
    sudo mkdir -p "$THEME_DIR/Assets"

    # Copy our QML files if present in repo
    [ -f "$SCRIPT_DIR/themes/sddm/necrodermis/Main.qml" ] && \
        sudo cp "$SCRIPT_DIR/themes/sddm/necrodermis/Main.qml" "$THEME_DIR/"
    [ -f "$SCRIPT_DIR/themes/sddm/necrodermis/Components/Clock.qml" ] && \
        sudo cp "$SCRIPT_DIR/themes/sddm/necrodermis/Components/Clock.qml" "$THEME_DIR/Components/"
    [ -f "$SCRIPT_DIR/themes/sddm/necrodermis/Components/LoginForm.qml" ] && \
        sudo cp "$SCRIPT_DIR/themes/sddm/necrodermis/Components/LoginForm.qml" "$THEME_DIR/Components/"
    [ -f "$SCRIPT_DIR/themes/sddm/necrodermis/Components/SystemButtons.qml" ] && \
        sudo cp "$SCRIPT_DIR/themes/sddm/necrodermis/Components/SystemButtons.qml" "$THEME_DIR/Components/"

    # Deploy Necrodermis necrodermis.conf colour/layout profile
    if [ -f "$SCRIPT_DIR/themes/sddm/necrodermis/necrodermis.conf" ]; then
        sudo cp "$SCRIPT_DIR/themes/sddm/necrodermis/necrodermis.conf" "$THEME_DIR/Themes/necrodermis.conf"
        # Point metadata.desktop at our profile
        sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/necrodermis.conf|' "$THEME_DIR/metadata.desktop"
        print_ok "NECRODERMIS theme profile deployed  ${DG}//  Themes/necrodermis.conf${NC}"
    else
        print_err "necrodermis.conf not found — SDDM will use astronaut defaults"
    fi

    # Background image (optional)
    if [ -f "$SCRIPT_DIR/themes/sddm/necrodermis/background.jpg" ]; then
        sudo cp "$SCRIPT_DIR/themes/sddm/necrodermis/background.jpg" \
            "$THEME_DIR/Backgrounds/necrodermis.jpg"
    fi

    # Weather script — necro_weather.py replaces weather.sh
    # Deployed to NECRO_HOME so it runs as the user, not as root under SDDM
    mkdir -p "$NECRO_HOME"
    if [ -f "$SCRIPT_DIR/scripts/necro_weather.py" ]; then
        cp "$SCRIPT_DIR/scripts/necro_weather.py" "$NECRO_HOME/necro_weather.py"
        chmod +x "$NECRO_HOME/necro_weather.py"
        print_ok "Weather script deployed  ${DG}//  $NECRO_HOME/necro_weather.py${NC}"
    else
        print_err "necro_weather.py not found in scripts/  //  weather widget will be empty"
    fi

    print_ok "Awakening interface uploaded  ${DG}//  sddm-astronaut-theme / necrodermis${NC}"

    # Weather service — runs necro_weather.py at boot, writes /tmp/necro_weather.txt
    # SDDM Clock.qml reads that file via XHR on a 10-minute timer
    local NECRO_WEATHER_PY="$NECRO_HOME/necro_weather.py"
    local VENV_PYTHON="$HOME/.local/share/sitrep_install/venv/bin/python"

    # Use sitrep's venv if available (has requests), fall back to system python3
    local WEATHER_PYTHON
    if [ -f "$VENV_PYTHON" ]; then
        WEATHER_PYTHON="$VENV_PYTHON"
    else
        WEATHER_PYTHON="$(command -v python3)"
    fi

    sudo tee /etc/systemd/system/necrodermis-weather.service > /dev/null <<EOF
[Unit]
Description=Necrodermis SDDM Weather Fetcher
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
ExecStart=/bin/bash -c 'python=$([ -f $HOME/.local/share/sitrep_install/venv/bin/python ] && echo $HOME/.local/share/sitrep_install/venv/bin/python || command -v python3); exec $python '$NECRO_WEATHER_PY

[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /etc/systemd/system/sddm.service.d
    sudo tee /etc/systemd/system/sddm.service.d/necrodermis.conf > /dev/null <<'EOF'
[Service]
Environment=QML_XHR_ALLOW_FILE_READ=1
EOF

    # Set SDDM theme in /etc/sddm.conf (not sddm.conf.d to avoid conflicts)
    if [ -f /etc/sddm.conf ]; then
        if grep -q "^\[Theme\]" /etc/sddm.conf; then
            sudo sed -i 's|^Current=.*|Current=sddm-astronaut-theme|' /etc/sddm.conf
        else
            echo -e "\n[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee -a /etc/sddm.conf > /dev/null
        fi
    else
        sudo tee /etc/sddm.conf > /dev/null <<'EOF'
[Theme]
Current=sddm-astronaut-theme
EOF
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable sddm
    sudo systemctl enable necrodermis-weather.service 2>/dev/null || true
    print_ok "Atmospheric service armed  ${DG}//  activates at next boot${NC}"

}
