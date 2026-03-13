#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/hyprlock.sh
# Installs hyprlock config with palette toggle:
#   Y (default) — wallust dynamic colors, registered as a wallust template
#   N           — hardcoded NECRODERMIS palette

install_hyprlock() {
    local HYPR_DIR="$HOME/.config/hypr"
    local WALLUST_DIR="$HOME/.config/wallust"
    local WALLUST_TEMPLATES="$WALLUST_DIR/templates"
    local WALLUST_TOML="$WALLUST_DIR/wallust.toml"
    local HYPRLOCK_DEST="$HYPR_DIR/hyprlock.conf"

    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local CONFIG_DIR="$SCRIPT_DIR/../../installer"

    necro_print "hyprlock" "Configuring hyprlock..."

    # ── Palette toggle ────────────────────────────────────────────────────────
    local use_wallust=true
    if gum confirm \
        --prompt.foreground="$GUM_CONFIRM_PROMPT_FOREGROUND" \
        --selected.background="$GUM_CONFIRM_SELECTED_BACKGROUND" \
        --unselected.foreground="$GUM_CONFIRM_UNSELECTED_FOREGROUND" \
        "Use wallust dynamic colors for hyprlock? (N = hardcoded Necrodermis palette)"; then
        use_wallust=true
    else
        use_wallust=false
    fi

    # ── Backup existing config ────────────────────────────────────────────────
    if [[ -f "$HYPRLOCK_DEST" ]]; then
        necro_backup "$HYPRLOCK_DEST"
    fi

    mkdir -p "$HYPR_DIR"

    # ── Deploy ────────────────────────────────────────────────────────────────
    if [[ "$use_wallust" == true ]]; then
        _hyprlock_install_wallust \
            "$CONFIG_DIR/hyprlock.conf.wallust" \
            "$WALLUST_TEMPLATES" \
            "$WALLUST_TOML" \
            "$HYPRLOCK_DEST"
    else
        _hyprlock_install_hardcoded \
            "$CONFIG_DIR/hyprlock.conf.necrodermis" \
            "$HYPRLOCK_DEST"
    fi
}

# ── Wallust path ──────────────────────────────────────────────────────────────
_hyprlock_install_wallust() {
    local src="$1"
    local template_dir="$2"
    local toml="$3"
    local dest="$4"
    local template_dest="$template_dir/hyprlock.conf"

    necro_print "hyprlock" "Installing wallust template..."

    # Place template where wallust can find it
    mkdir -p "$template_dir"
    necro_run cp "$src" "$template_dest"

    # Register in wallust.toml if not already present
    if [[ -f "$toml" ]]; then
        if ! grep -q "hyprlock.conf" "$toml"; then
            necro_print "hyprlock" "Registering template in wallust.toml..."
            # Append entry under [templates] section if it exists, else append block
            if grep -q '^\[templates\]' "$toml"; then
                # Insert after [templates] line
                necro_run sed -i '/^\[templates\]/a\\nhyprlock = { template = "'"$template_dest"'", output = "'"$dest"'" }' "$toml"
            else
                printf '\n[templates]\nhyprlock = { template = "%s", output = "%s" }\n' \
                    "$template_dest" "$dest" >> "$toml"
            fi
        else
            necro_print "hyprlock" "wallust.toml already has hyprlock entry — skipping."
        fi
    else
        # wallust.toml missing entirely — create minimal one with just this entry
        necro_print "hyprlock" "wallust.toml not found — creating with hyprlock entry..."
        mkdir -p "$(dirname "$toml")"
        printf '[templates]\nhyprlock = { template = "%s", output = "%s" }\n' \
            "$template_dest" "$dest" > "$toml"
    fi

    # Run wallust once to generate the initial output from current colors
    if command -v wallust &>/dev/null; then
        necro_print "hyprlock" "Running wallust apply to generate initial config..."
        necro_run wallust apply || necro_print "hyprlock" "wallust apply failed — config will generate on next wallpaper change."
    else
        necro_print "hyprlock" "wallust not found in PATH — template registered, will apply on next wallpaper change."
    fi

    necro_print "hyprlock" "Wallust dynamic palette installed."
}

# ── Hardcoded path ────────────────────────────────────────────────────────────
_hyprlock_install_hardcoded() {
    local src="$1"
    local dest="$2"

    necro_print "hyprlock" "Installing hardcoded Necrodermis palette..."
    necro_run cp "$src" "$dest"
    necro_print "hyprlock" "Hardcoded palette installed."
    local REPO_ROOT
    REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    # Scale hyprlock positions to primary monitor resolution
    if [[ -f "$REPO_ROOT/scripts/necro-hyprlock-scale.sh" ]]; then
        bash "$REPO_ROOT/scripts/necro-hyprlock-scale.sh"
    fi
}
