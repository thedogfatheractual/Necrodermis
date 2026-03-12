#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — TRIAGE + NURSE + CRITICAL FAILURE SYSTEM
# Append entire contents to the bottom of scripts/common.sh
# ════════════════════════════════════════════════════════════

# ── GLOBALS ──
YAY_AVAILABLE=false
NECRO_LOG_FILE="${NECRO_LOG_FILE:-$HOME/.local/share/necrodermis/install.log}"
NECRO_FAIL_COUNT=0
NECRO_SKIP_COUNT=0
NECRO_OK_COUNT=0
NECRO_TRIAGE_MAX_ATTEMPTS=3   # Max triage checks before circuit break
NECRO_TRIAGE_TIMEOUT=30       # Seconds before a single triage attempt is abandoned
NECRO_NURSE_TIMEOUT=10        # Seconds to wait at nurse prompt before limping on
NECRO_CRITICAL_TIMEOUT=30     # Seconds to wait at critical prompt before exit


# ════════════════════════════════════════════════════════════
# NECRO_LOG
# ════════════════════════════════════════════════════════════
# Usage: necro_log "LEVEL" "component" "message"
# Levels: OK | SKIP | FAIL | FUBAR | INFO | RETRY | NURSE | CRIT
necro_log() {
    local level="$1"
    local component="$2"
    local msg="$3"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    mkdir -p "$(dirname "$NECRO_LOG_FILE")"
    printf "[%s] [%-5s] %-30s %s\n" "$timestamp" "$level" "$component" "$msg" \
        >> "$NECRO_LOG_FILE"

    case "$level" in
        OK)               (( NECRO_OK_COUNT++   )) ;;
        SKIP)             (( NECRO_SKIP_COUNT++ )) ;;
        FAIL|FUBAR|CRIT)  (( NECRO_FAIL_COUNT++ )) ;;
    esac
}


# ════════════════════════════════════════════════════════════
# NECRO_INIT_LOG
# ════════════════════════════════════════════════════════════
# Call once at the top of install.sh to initialise the log file.
necro_init_log() {
    mkdir -p "$(dirname "$NECRO_LOG_FILE")"
    {
        echo "════════════════════════════════════════════════════════════"
        echo "  NECRODERMIS INSTALL LOG"
        echo "  Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "  Host: $(uname -n)  //  Distro: ${DISTRO:-unknown}"
        echo "════════════════════════════════════════════════════════════"
        echo ""
    } > "$NECRO_LOG_FILE"
    print_info "Install log initialised  //  ${NECRO_LOG_FILE}"
}


# ════════════════════════════════════════════════════════════
# NECRO_OPEN_LOG_TERMINAL
# ════════════════════════════════════════════════════════════
# Tries to open a terminal window showing the tail of the install log.
# Falls back gracefully: kitty → foot → xterm → inline print.
# In TTY (no DISPLAY/WAYLAND_DISPLAY) always falls back to inline.
necro_open_log_terminal() {
    local log_cmd="echo ''; echo '  ══ NECRODERMIS DIAGNOSTIC LOG ══'; echo ''; tail -60 ${NECRO_LOG_FILE}; echo ''; echo '  ══ END OF LOG  (scroll up for full output) ══'; echo ''; read -p \"  Press ENTER to close...\" _"

    # Only try to open a graphical terminal if we're in a graphical session
    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
        if command -v kitty &>/dev/null; then
            kitty --title "NECRODERMIS DIAGNOSTIC LOG" bash -c "$log_cmd" &
            return 0
        elif command -v foot &>/dev/null; then
            foot --title "NECRODERMIS DIAGNOSTIC LOG" bash -c "$log_cmd" &
            return 0
        elif command -v xterm &>/dev/null; then
            xterm -title "NECRODERMIS DIAGNOSTIC LOG" \
                -fg green -bg black \
                -e bash -c "$log_cmd" &
            return 0
        fi
    fi

    # TTY or no terminal emulator available — print inline
    echo ""
    echo -e "${R}${B}  ══ NECRODERMIS DIAGNOSTIC LOG (last 60 lines) ══${NC}"
    echo ""
    tail -60 "$NECRO_LOG_FILE" | while IFS= read -r line; do
        echo -e "  ${DG}${line}${NC}"
    done
    echo ""
    echo -e "${R}${B}  ══ END OF LOG ══${NC}"
    echo -e "  ${DG}  Full log: cat ${NECRO_LOG_FILE}${NC}"
    echo ""
}


# ════════════════════════════════════════════════════════════
# NECRO_CRITICAL_FAILURE
# ════════════════════════════════════════════════════════════
# Called when a CRITICAL component fails all triage and nurse routes.
# Opens a terminal with the log tail, presents two options:
#   - Restart installer from top
#   - Exit and diagnose
# Auto-exits after NECRO_CRITICAL_TIMEOUT seconds if no input.
#
# Usage: necro_critical_failure "component" "failed_cmd" "what_we_tried"
# Does not return — always exits or restarts.
necro_critical_failure() {
    local component="$1"
    local failed_cmd="$2"
    local what_we_tried="$3"
    local pkg_name
    pkg_name=$(echo "$failed_cmd" | awk '{print $NF}')

    necro_log "CRIT" "$component" \
        "CRITICAL FAILURE — awakening sequence cannot continue  //  ${pkg_name}"

    echo ""
    echo -e "${R}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${R}${B}  ║   ██████╗ ██████╗ ██╗████████╗██╗ ██████╗ █████╗ ██╗        ║${NC}"
    echo -e "${R}${B}  ║  ██╔════╝██╔══██╗██║╚══██╔══╝██║██╔════╝██╔══██╗██║        ║${NC}"
    echo -e "${R}${B}  ║  ██║     ██████╔╝██║   ██║   ██║██║     ███████║██║        ║${NC}"
    echo -e "${R}${B}  ║  ██║     ██╔══██╗██║   ██║   ██║██║     ██╔══██║██║        ║${NC}"
    echo -e "${R}${B}  ║  ╚██████╗██║  ██║██║   ██║   ██║╚██████╗██║  ██║███████╗   ║${NC}"
    echo -e "${R}${B}  ║   ╚═════╝╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ║${NC}"
    echo -e "${R}${B}  ║                                                              ║${NC}"
    echo -e "${R}${B}  ║   TOMB INTEGRITY BREACH — AWAKENING SEQUENCE HALTED          ║${NC}"
    echo -e "${R}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${R}  CRITICAL COMPONENT:${NC}  ${B}${component}${NC}"
    echo -e "  ${R}  Failed command:${NC}     ${failed_cmd}"
    echo -e "  ${R}  Package/target:${NC}     ${pkg_name}"
    echo -e "  ${R}  Routes attempted:${NC}   ${what_we_tried}"
    echo ""
    echo -e "  ${Y}  This component is required for Necrodermis to function.${NC}"
    echo -e "  ${Y}  The awakening sequence cannot proceed without it.${NC}"
    echo -e "  ${Y}  The Canoptek units have no further repair protocols.${NC}"
    echo ""
    echo -e "  ${DG}  Opening diagnostic log...${NC}"
    echo ""

    # Open the log — graphical terminal if available, inline if not
    necro_open_log_terminal
    sleep 1

    echo -e "  ${Y}  Auto-exiting in ${NECRO_CRITICAL_TIMEOUT}s if no directive is given.${NC}"
    echo ""

    # ── CRITICAL CHOICE — restart or exit ──
    local crit_choice
    crit_choice=$(
        timeout "$NECRO_CRITICAL_TIMEOUT" \
        gum choose \
            --header="  TOMB DIRECTIVE  //  how do you wish to proceed?" \
            --header.foreground="1" \
            --cursor.foreground="2" \
            --selected.foreground="2" \
            --item.foreground="7" \
            "  RESTART AWAKENING   //  return to start and try again" \
            "  EXIT AND DIAGNOSE   //  halt sequence and review the log" \
        2>/dev/null
    ) || crit_choice="timeout"

    case "$crit_choice" in

        *"RESTART AWAKENING"*)
            echo ""
            echo -e "  ${G}  Rebooting awakening sequence...${NC}"
            echo -e "  ${DG}  The tomb stirs again. May the next attempt hold.${NC}"
            echo ""
            necro_log "CRIT" "$component" "Organic directive: restart installer"
            sleep 1
            exec bash "$SCRIPT_DIR/install.sh"
            ;;

        *"EXIT AND DIAGNOSE"* | "timeout" | *)
            echo ""
            echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${G}${B}  ║   AWAKENING SEQUENCE TERMINATED                              ║${NC}"
            echo -e "${G}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            if [[ "$crit_choice" == "timeout" ]]; then
                echo -e "  ${DG}  No directive received — exiting.${NC}"
                necro_log "CRIT" "$component" "Critical timeout — auto-exit"
            else
                necro_log "CRIT" "$component" "Organic directive: exit and diagnose"
            fi
            echo ""
            echo -e "  ${B}  ── CRITICAL COMPONENT ─────────────────────────────────────${NC}"
            echo -e "  ${R}  ${component}${NC}  failed to install  //  ${pkg_name}"
            echo ""
            echo -e "  ${B}  ── DIAGNOSTIC LOG ──────────────────────────────────────────${NC}"
            echo -e "  ${G}    cat ${NECRO_LOG_FILE}${NC}"
            echo ""
            echo -e "  ${B}  ── RESTART WHEN READY ──────────────────────────────────────${NC}"
            echo -e "  ${G}    bash ~/Necrodermis/install.sh${NC}"
            echo ""
            echo -e "  ${B}  ── REPORT A BUG ────────────────────────────────────────────${NC}"
            echo -e "  ${G}    https://github.com/thedogfatheractual/Necrodermis/issues${NC}"
            echo ""
            echo -e "  ${DG}  The stars remember. The tomb will wait.${NC}"
            echo ""
            exit 1
            ;;
    esac
}


# ════════════════════════════════════════════════════════════
# NECRO_NURSE
# ════════════════════════════════════════════════════════════
# Last resort before limp mode (non-critical) or critical failure.
# Presents failure to user, offers manual fix or full pause.
# Auto-continues after NECRO_NURSE_TIMEOUT seconds if no input.
# If is_critical=true, routes to necro_critical_failure on give-up.
#
# Usage: necro_nurse "component" "failed_cmd" "what_we_tried" [is_critical]
# Returns: 0 = user fixed it, 1 = limping on (non-critical only)
necro_nurse() {
    local component="$1"
    local failed_cmd="$2"
    local what_we_tried="$3"
    local is_critical="${4:-false}"
    local pkg_name
    pkg_name=$(echo "$failed_cmd" | awk '{print $NF}')

    echo ""
    echo -e "${Y}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${Y}${B}  ║   CANOPTEK DIAGNOSTIC UNIT — INTERVENTION REQUIRED          ║${NC}"
    echo -e "${Y}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${R}  COMPONENT FAILURE:${NC}  ${B}${component}${NC}"
    [[ "$is_critical" == "true" ]] && \
        echo -e "  ${R}${B}  ⚠  CRITICAL COMPONENT — installer cannot continue without this${NC}"
    echo -e "  ${DG}  Failed command:${NC}     ${failed_cmd}"
    echo -e "  ${DG}  Package/target:${NC}     ${pkg_name}"
    echo -e "  ${DG}  Routes attempted:${NC}   ${what_we_tried}"
    echo ""
    echo -e "  ${DG}  The Canoptek units have exhausted automated repair protocols.${NC}"
    echo -e "  ${DG}  Organic intervention may be required.${NC}"
    echo -e "  ${Y}  Auto-continuing in ${NECRO_NURSE_TIMEOUT}s if no directive is given.${NC}"
    echo ""

    # ── TIMED CHOICE ──
    local nurse_choice
    nurse_choice=$(
        timeout "$NECRO_NURSE_TIMEOUT" \
        gum choose \
            --header="  CANOPTEK DIRECTIVE  //  what are your orders?" \
            --header.foreground="3" \
            --cursor.foreground="2" \
            --selected.foreground="2" \
            --item.foreground="7" \
            "  I KNOW THE FIX    //  let me run a command or provide a path" \
            "  LET ME THINK...   //  pause the awakening sequence" \
            "  ACCEPTABLE LOSS   //  log it and continue" \
        2>/dev/null
    ) || nurse_choice="timeout"

    case "$nurse_choice" in

        # ── OPTION 1: User knows the fix ──
        *"I KNOW THE FIX"*)
            echo ""
            echo -e "  ${G}  Enter the command or path to resolve this fault:${NC}"
            echo -e "  ${DG}  Component:  ${component}${NC}"
            echo -e "  ${DG}  Target:     ${pkg_name}${NC}"
            echo -e "  ${DG}  Examples:${NC}"
            echo -e "  ${DG}    sudo pacman -S ${pkg_name}${NC}"
            echo -e "  ${DG}    ln -s /usr/bin/${pkg_name} ~/.local/bin/${pkg_name}${NC}"
            echo ""
            local user_cmd
            user_cmd=$(gum input \
                --placeholder="  enter command..." \
                --prompt="  ⟩ " \
                --prompt.foreground="2" \
                --cursor.foreground="2" \
                --width=70)

            if [[ -z "$user_cmd" ]]; then
                necro_log "NURSE" "$component" "No organic directive entered — moving on"
                print_info "No command entered  //  logging fault and continuing"
                [[ "$is_critical" == "true" ]] && \
                    necro_critical_failure "$component" "$failed_cmd" "$what_we_tried"
                return 1
            fi

            echo ""
            print_info "Executing organic directive  //  ${user_cmd}"
            necro_log "NURSE" "$component" "Organic directive: $user_cmd"

            if eval "$user_cmd"; then
                necro_log "NURSE" "$component" "Organic intervention succeeded  //  $user_cmd"
                print_ok "${component}  ${DG}//  fault resolved — continuing${NC}"
                return 0
            else
                necro_log "NURSE" "$component" "Organic directive failed  //  $user_cmd"
                print_err "${component}  //  command failed"
                [[ "$is_critical" == "true" ]] && \
                    necro_critical_failure "$component" "$failed_cmd" "$what_we_tried"
                return 1
            fi
            ;;

        # ── OPTION 2: User wants to think — pause and hand them the controls ──
        *"LET ME THINK"*)
            echo ""
            echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${G}${B}  ║   STASIS PAUSE  //  AWAKENING SEQUENCE SUSPENDED            ║${NC}"
            echo -e "${G}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "  ${DG}  The tomb is patient. Take what time you require.${NC}"
            echo ""
            echo -e "  ${B}  ── FAULT DETAILS ──────────────────────────────────────────${NC}"
            echo -e "  ${R}  Component:${NC}       ${component}"
            [[ "$is_critical" == "true" ]] && \
                echo -e "  ${R}${B}  ⚠  CRITICAL  //  installer cannot continue without this${NC}"
            echo -e "  ${R}  Failed command:${NC}  ${failed_cmd}"
            echo -e "  ${R}  Package target:${NC}  ${pkg_name}"
            echo -e "  ${R}  Routes tried:${NC}    ${what_we_tried}"
            echo ""
            echo -e "  ${B}  ── RESUME AWAKENING SEQUENCE ───────────────────────────────${NC}"
            echo -e "  ${G}    bash ~/Necrodermis/install.sh --resume${NC}"
            echo -e "  ${DG}  (completed components will be skipped)${NC}"
            echo ""
            echo -e "  ${B}  ── READ DIAGNOSTIC LOG ─────────────────────────────────────${NC}"
            echo -e "  ${G}    cat ${NECRO_LOG_FILE}${NC}"
            echo ""
            echo -e "  ${DG}  The stars remember. The tomb awaits your return.${NC}"
            echo ""
            necro_log "NURSE" "$component" \
                "Awakening sequence suspended by organic directive — awaiting manual resume"
            exit 0
            ;;

        # ── OPTION 3 or TIMEOUT: Move on / give up ──
        *"ACCEPTABLE LOSS"* | "timeout" | *)
            echo ""
            if [[ "$nurse_choice" == "timeout" ]]; then
                print_info "No directive received  //  ${component} flagged in log"
                necro_log "NURSE" "$component" \
                    "Nurse timeout (${NECRO_NURSE_TIMEOUT}s) — limp mode  //  ${pkg_name}"
            else
                print_info "Acceptable loss confirmed  //  ${component} flagged in log"
                necro_log "NURSE" "$component" \
                    "Acceptable loss — limp mode  //  ${pkg_name}"
            fi

            # Critical components don't get limp mode — they escalate
            if [[ "$is_critical" == "true" ]]; then
                necro_critical_failure "$component" "$failed_cmd" "$what_we_tried"
            fi

            return 1
            ;;
    esac
}


# ════════════════════════════════════════════════════════════
# NECRO_TRIAGE
# ════════════════════════════════════════════════════════════
# Called by necro_pkg / necro_yay on failure.
# Runs a capped logic chain — max attempts + timeout circuit breaker.
# On exhaustion: passes to necro_nurse.
# If critical=true, nurse eventually calls necro_critical_failure.
#
# Usage: necro_triage "component" "failed_cmd" "pacman|yay|generic" ["critical"]
# Returns: 0 = recovered, 1 = limp on (non-critical only)
necro_triage() {
    local component="$1"
    local failed_cmd="$2"
    local failure_type="${3:-generic}"
    local is_critical="${4:-false}"
    local attempts=0
    local start_time
    start_time=$(date +%s)
    local what_we_tried=""

    necro_log "INFO" "$component" "Triage initiated  //  failed: $failed_cmd"
    print_info "Triage engaged  //  ${component}"

    # ── CIRCUIT BREAKER ──
    # Call before each triage check.
    # Returns 1 if attempt cap or elapsed time exceeded — triggers nurse.
    _triage_check() {
        (( attempts++ ))
        local elapsed=$(( $(date +%s) - start_time ))

        if (( attempts > NECRO_TRIAGE_MAX_ATTEMPTS )); then
            necro_log "FUBAR" "$component" \
                "Circuit break — max attempts (${NECRO_TRIAGE_MAX_ATTEMPTS}) reached"
            return 1
        fi

        if (( elapsed > NECRO_TRIAGE_TIMEOUT )); then
            necro_log "FUBAR" "$component" \
                "Circuit break — timeout (${elapsed}s > ${NECRO_TRIAGE_TIMEOUT}s)"
            return 1
        fi

        return 0
    }

    # ── CHECK 1: yay missing from PATH — can we restore it? ──
    _triage_check || {
        necro_nurse "$component" "$failed_cmd" "${what_we_tried:-none}" "$is_critical"
        return $?
    }
    if [[ "$failure_type" == "yay" ]] && ! command -v yay &>/dev/null; then
        what_we_tried+="[yay re-init] "
        print_info "yay not in PATH  //  attempting re-initialisation..."
        if source "${SCRIPT_DIR}/scripts/functions/yay.sh" 2>/dev/null \
            && install_yay 2>/dev/null; then
            YAY_AVAILABLE=true
            print_info "yay restored  //  retrying ${component}..."
            if timeout "$NECRO_TRIAGE_TIMEOUT" bash -c "$failed_cmd" 2>/dev/null; then
                necro_log "OK" "$component" "Recovered after yay re-init"
                return 0
            fi
        fi
        necro_log "INFO" "$component" "yay re-init failed"
    fi

    # ── CHECK 2: Does pacman have it instead? ──
    _triage_check || {
        necro_nurse "$component" "$failed_cmd" "${what_we_tried:-none}" "$is_critical"
        return $?
    }
    if [[ "$failure_type" == "yay" ]]; then
        what_we_tried+="[pacman fallback] "
        local pkg_name
        pkg_name=$(echo "$failed_cmd" | awk '{print $NF}')
        if [[ -n "$pkg_name" ]] && pacman -Si "$pkg_name" &>/dev/null; then
            print_info "AUR → pacman fallback  //  ${pkg_name}"
            if timeout "$NECRO_TRIAGE_TIMEOUT" \
                sudo pacman -S --needed --noconfirm "$pkg_name" 2>/dev/null; then
                necro_log "OK" "$component" "pacman fallback succeeded  //  $pkg_name"
                return 0
            fi
        else
            necro_log "INFO" "$component" "No pacman fallback for ${pkg_name:-unknown}"
        fi
    fi

    # ── CHECK 3: Binary exists but not in PATH? ──
    _triage_check || {
        necro_nurse "$component" "$failed_cmd" "${what_we_tried:-none}" "$is_critical"
        return $?
    }
    what_we_tried+="[path hunt] "
    local bin_name
    bin_name=$(echo "$failed_cmd" | awk '{print $1}')
    if ! command -v "$bin_name" &>/dev/null; then
        local bin_path
        bin_path=$(find /usr/bin /usr/local/bin "$HOME/.local/bin" \
            -name "$bin_name" 2>/dev/null | head -1)
        if [[ -n "$bin_path" ]]; then
            print_info "Binary found at ${bin_path}  //  updating PATH"
            export PATH="$PATH:$(dirname "$bin_path")"
            if timeout "$NECRO_TRIAGE_TIMEOUT" bash -c "$failed_cmd" 2>/dev/null; then
                necro_log "OK" "$component" "Recovered after PATH fix  //  $bin_path"
                return 0
            fi
        else
            necro_log "INFO" "$component" "Binary '$bin_name' not found on system"
        fi
    fi

    # ── ALL AUTOMATED ROUTES EXHAUSTED — PASS TO NURSE ──
    necro_log "FUBAR" "$component" \
        "All triage routes exhausted  //  tried: $what_we_tried"
    necro_nurse "$component" "$failed_cmd" "$what_we_tried" "$is_critical"
    return $?
}


# ════════════════════════════════════════════════════════════
# NECRO_PKG  /  NECRO_PKG_CRITICAL
# ════════════════════════════════════════════════════════════
# Drop-in for: sudo pacman -S --needed --noconfirm <pkg> [pkg...]
# necro_pkg          — failure is limp-mode-able
# necro_pkg_critical — failure halts the installer
#
# Usage: necro_pkg "component_label" pkg1 pkg2 pkg3
#        necro_pkg_critical "component_label" pkg1 pkg2 pkg3
necro_pkg() {
    local component="$1"; shift
    local pkgs=("$@")

    if sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>&1; then
        necro_log "OK" "$component" "pacman: ${pkgs[*]}"
        print_ok "${component}  ${DG}//  packages installed${NC}"
    else
        necro_log "FAIL" "$component" "pacman failed: ${pkgs[*]}"
        print_err "${component}  //  pacman failed — engaging triage"
        necro_triage "$component" \
            "sudo pacman -S --needed --noconfirm ${pkgs[*]}" "pacman" "false" || true
    fi
}

necro_pkg_critical() {
    local component="$1"; shift
    local pkgs=("$@")

    if sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>&1; then
        necro_log "OK" "$component" "pacman: ${pkgs[*]}"
        print_ok "${component}  ${DG}//  packages installed${NC}"
    else
        necro_log "FAIL" "$component" "pacman failed (CRITICAL): ${pkgs[*]}"
        print_err "${component}  //  pacman failed — engaging triage  ${R}[CRITICAL]${NC}"
        necro_triage "$component" \
            "sudo pacman -S --needed --noconfirm ${pkgs[*]}" "pacman" "critical"
    fi
}


# ════════════════════════════════════════════════════════════
# NECRO_YAY  /  NECRO_YAY_CRITICAL
# ════════════════════════════════════════════════════════════
# Drop-in for: yay -S --needed --noconfirm <pkg> [pkg...]
# necro_yay          — failure is limp-mode-able
# necro_yay_critical — failure halts the installer
#
# Usage: necro_yay "component_label" pkg1 pkg2
#        necro_yay_critical "component_label" pkg1 pkg2
necro_yay() {
    local component="$1"; shift
    local pkgs=("$@")

    if ! $YAY_AVAILABLE && ! command -v yay &>/dev/null; then
        necro_log "SKIP" "$component" "yay unavailable — skipped: ${pkgs[*]}"
        print_skip "${component}  //  yay unavailable — skipped"
        return 0
    fi

    if yay -S --needed --noconfirm "${pkgs[@]}" 2>&1; then
        necro_log "OK" "$component" "yay: ${pkgs[*]}"
        print_ok "${component}  ${DG}//  AUR packages installed${NC}"
    else
        necro_log "FAIL" "$component" "yay failed: ${pkgs[*]}"
        print_err "${component}  //  yay failed — engaging triage"
        necro_triage "$component" \
            "yay -S --needed --noconfirm ${pkgs[*]}" "yay" "false" || true
    fi
}

necro_yay_critical() {
    local component="$1"; shift
    local pkgs=("$@")

    if yay -S --needed --noconfirm "${pkgs[@]}" 2>&1; then
        necro_log "OK" "$component" "yay: ${pkgs[*]}"
        print_ok "${component}  ${DG}//  AUR packages installed${NC}"
    else
        necro_log "FAIL" "$component" "yay failed (CRITICAL): ${pkgs[*]}"
        print_err "${component}  //  yay failed — engaging triage  ${R}[CRITICAL]${NC}"
        necro_triage "$component" \
            "yay -S --needed --noconfirm ${pkgs[*]}" "yay" "critical"
    fi
}


# ════════════════════════════════════════════════════════════
# NECRO_PRINT_SUMMARY
# ════════════════════════════════════════════════════════════
# Call at the very end of install.sh — inline fault report + log pointer.
necro_print_summary() {
    echo ""
    print_section "INSTALLATION REPORT  //  TOMB WORLD DIAGNOSTIC SUMMARY"
    echo ""
    echo -e "  ${G}  ✓  Successful:${NC}  ${NECRO_OK_COUNT}"
    echo -e "  ${Y}  ·  Skipped:${NC}    ${NECRO_SKIP_COUNT}"
    echo -e "  ${R}  ✗  Failed:${NC}     ${NECRO_FAIL_COUNT}"
    echo ""

    if (( NECRO_FAIL_COUNT > 0 )); then
        echo -e "  ${Y}  Some components could not be installed.${NC}"
        echo -e "  ${Y}  The tomb world is operational — with known fault states.${NC}"
        echo ""
        echo -e "  ${R}  ── FAILED COMPONENTS ──────────────────────────────────────${NC}"
        grep -E "\[(FAIL |FUBAR|NURSE|CRIT )\]" "$NECRO_LOG_FILE" 2>/dev/null \
            | while IFS= read -r line; do
                echo -e "  ${DG}  $line${NC}"
            done
        echo ""
        echo -e "  ${B}  ── FULL DIAGNOSTIC LOG ─────────────────────────────────────${NC}"
        echo -e "  ${G}    cat ${NECRO_LOG_FILE}${NC}"
        echo ""
        echo -e "  ${B}  ── RESUME AFTER MANUAL FIXES ───────────────────────────────${NC}"
        echo -e "  ${G}    bash ~/Necrodermis/install.sh --resume${NC}"
        echo ""
        echo -e "  ${B}  ── REPORT A BUG ────────────────────────────────────────────${NC}"
        echo -e "  ${G}    https://github.com/thedogfatheractual/Necrodermis/issues${NC}"
        echo ""
    else
        echo -e "  ${G}  All components installed without incident.${NC}"
        echo -e "  ${DG}  The tomb world is fully operational.${NC}"
        echo ""
    fi
}
