#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/sitrep.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_sitrep

install_sitrep() {
    print_section "SITREP  //  ATMOSPHERIC INTELLIGENCE ACQUISITION"
    echo ""
    echo -e "${DG}  Sitrep provides METAR weather data for the SDDM login display${NC}"
    echo -e "${DG}  and the terminal weather readout. Requires Python 3 and internet${NC}"
    echo -e "${DG}  access at boot to fetch conditions from aviationweather.gov.${NC}"
    echo ""

    local SITREP_INSTALL_ROOT="$HOME/.local/share/sitrep_install"
    local SITREP_VENV="$SITREP_INSTALL_ROOT/venv"
    local SITREP_BIN="$HOME/.local/bin/sitrep"
    local SITREP_SCRIPT="$SITREP_INSTALL_ROOT/Sitrep.py"
    local SITREP_CONFIG_DIR="$HOME/.config/sitrep"
    local SITREP_CONFIG="$SITREP_CONFIG_DIR/config.ini"

    # ── Already installed? ──
    if [ -f "$SITREP_BIN" ] && [ -f "$SITREP_SCRIPT" ]; then
        print_ok "Sitrep already installed  ${DG}//  skipping${NC}"
        # Ensure config exists with a sane ICAO — configure_location will overwrite it
        if [ ! -f "$SITREP_CONFIG" ]; then
            mkdir -p "$SITREP_CONFIG_DIR"
            printf "[Weather]\nicao_code = CYWG\n" > "$SITREP_CONFIG"
            print_info "Config initialised  //  ICAO will be set during location setup"
        fi
        return 0
    fi

    # ── Python check ──
    if ! command -v python3 &>/dev/null; then
        print_err "python3 not found — install it first (included in base deps)"
        return 1
    fi

    # ── Create venv ──
    print_info "Creating Python virtual environment  //  $SITREP_VENV"
    mkdir -p "$SITREP_INSTALL_ROOT"
    python3 -m venv "$SITREP_VENV"

    # ── Install Python deps into venv ──
    print_info "Installing Python dependencies  //  requests, tzlocal"
    "$SITREP_VENV/bin/pip" install --quiet "requests>=2.28" "tzlocal>=4.0"

    # ── Pull Sitrep.py from repo ──
    print_info "Acquiring Sitrep from repo..."
    if ! command -v git &>/dev/null; then
        necro_pkg "git" "git" "git" "git" "git"
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    if ! git clone --depth=1 "https://github.com/thedogfatheractual/sitrep.git" "$tmp_dir/sitrep" 2>/dev/null; then
        rm -rf "$tmp_dir"
        print_err "Sitrep clone failed  //  network required"
        print_info "Re-run the installer with an active connection to enable weather"
        return 1
    fi

    if [ ! -f "$tmp_dir/sitrep/install_sitrep_full.sh" ]; then
        rm -rf "$tmp_dir"
        print_err "Sitrep repo structure unexpected  //  install_sitrep_full.sh not found"
        print_info "Check https://github.com/thedogfatheractual/sitrep"
        return 1
    fi

    bash "$tmp_dir/sitrep/install_sitrep_full.sh"
    rm -rf "$tmp_dir"
    print_ok "Sitrep installed  ${DG}//  sensors online${NC}"
    print_info "Run 'sitrep' in terminal for full aviation weather"
}
