#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — TRIAGE + NURSE + CRITICAL FAILURE SYSTEM
# Sourced by scripts/common.sh — do not run directly
# ════════════════════════════════════════════════════════════

# ── GLOBALS ──
YAY_AVAILABLE=false
NECRO_LOG_FILE="${NECRO_LOG_FILE:-$HOME/.local/share/necrodermis/install.log}"
NECRO_FAIL_COUNT=0
NECRO_SKIP_COUNT=0
NECRO_OK_COUNT=0
NECRO_TRIAGE_MAX_ATTEMPTS=3
NECRO_TRIAGE_TIMEOUT=30
NECRO_NURSE_TIMEOUT=10
NECRO_CRITICAL_TIMEOUT=30
NECRO_STAGE_CURRENT=0
NECRO_STAGE_TOTAL=0


# ════════════════════════════════════════════════════════════
# NECRO_LOG
# ════════════════════════════════════════════════════════════
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
necro_open_log_terminal() {
    local log_cmd="echo ''; echo '  ══ NECRODERMIS DIAGNOSTIC LOG ══'; echo ''; tail -60 ${NECRO_LOG_FILE}; echo ''; echo '  ══ END OF LOG  (scroll up for full output) ══'; echo ''; read -p \"  Press ENTER to close...\" _"

    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
        if command -v kitty &>/dev/null; then
            kitty --title "NECRODERMIS DIAGNOSTIC LOG" bash -c "$log_cmd" &
            return 0
        elif command -v foot &>/dev/null; then
            foot --title "NECRODERMIS DIAGNOSTIC LOG" bash -c "$log_cmd" &
            return 0
        elif command -v xterm &>/dev/null; then
            xterm -title "NECRODERMIS DIAGNOSTIC LOG" -fg green -bg black \
                -e bash -c "$log_cmd" &
            return 0
        fi
    fi

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
    echo ""
    echo -e "  ${DG}  Opening diagnostic log...${NC}"
    echo ""

    necro_open_log_terminal
    sleep 1

    echo -e "  ${Y}  Auto-exiting in ${NECRO_CRITICAL_TIMEOUT}s if no directive is given.${NC}"
    echo ""

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
                necro_log "CRIT" "$component" "Critical timeout — auto-exit"
            else
                necro_log "CRIT" "$component" "Organic directive: exit and diagnose"
            fi
            echo -e "  ${G}    cat ${NECRO_LOG_FILE}${NC}"
            echo -e "  ${G}    bash ~/Necrodermis/install.sh${NC}"
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
    echo -e "  ${Y}  Auto-continuing in ${NECRO_NURSE_TIMEOUT}s if no directive is given.${NC}"
    echo ""

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
        *"I KNOW THE FIX"*)
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
                [[ "$is_critical" == "true" ]] && \
                    necro_critical_failure "$component" "$failed_cmd" "$what_we_tried"
                return 1
            fi

            necro_log "NURSE" "$component" "Organic directive: $user_cmd"
            if eval "$user_cmd"; then
                necro_log "NURSE" "$component" "Organic intervention succeeded"
                print_ok "${component}  ${DG}//  fault resolved — continuing${NC}"
                return 0
            else
                necro_log "NURSE" "$component" "Organic directive failed"
                [[ "$is_critical" == "true" ]] && \
                    necro_critical_failure "$component" "$failed_cmd" "$what_we_tried"
                return 1
            fi
            ;;

        *"LET ME THINK"*)
            echo ""
            echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${G}${B}  ║   STASIS PAUSE  //  AWAKENING SEQUENCE SUSPENDED            ║${NC}"
            echo -e "${G}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "  ${R}  Component:  ${component}${NC}"
            echo -e "  ${G}    bash ~/Necrodermis/install.sh --resume${NC}"
            echo -e "  ${G}    cat ${NECRO_LOG_FILE}${NC}"
            echo ""
            necro_log "NURSE" "$component" "Awakening sequence suspended — awaiting manual resume"
            exit 0
            ;;

        *"ACCEPTABLE LOSS"* | "timeout" | *)
            echo ""
            if [[ "$nurse_choice" == "timeout" ]]; then
                necro_log "NURSE" "$component" "Nurse timeout — limp mode  //  ${pkg_name}"
            else
                necro_log "NURSE" "$component" "Acceptable loss — limp mode  //  ${pkg_name}"
            fi

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

    _necro_triage_check() {
        (( attempts++ ))
        local elapsed=$(( $(date +%s) - start_time ))
        if (( attempts > NECRO_TRIAGE_MAX_ATTEMPTS )); then
            necro_log "FUBAR" "$component" "Circuit break — max attempts reached"
            return 1
        fi
        if (( elapsed > NECRO_TRIAGE_TIMEOUT )); then
            necro_log "FUBAR" "$component" "Circuit break — timeout"
            return 1
        fi
        return 0
    }

    # ── CHECK 1: yay not in PATH ──
    _necro_triage_check || { necro_nurse "$component" "$failed_cmd" "${what_we_tried:-none}" "$is_critical"; return $?; }
    if [[ "$failure_type" == "yay" ]] && ! command -v yay &>/dev/null; then
        what_we_tried+="[yay re-init] "
        if source "${SCRIPT_DIR}/scripts/functions/yay.sh" 2>/dev/null && install_yay 2>/dev/null; then
            YAY_AVAILABLE=true
            if timeout "$NECRO_TRIAGE_TIMEOUT" bash -c "$failed_cmd" 2>/dev/null; then
                necro_log "OK" "$component" "Recovered after yay re-init"
                return 0
            fi
        fi
    fi

    # ── CHECK 2: pacman fallback ──
    _necro_triage_check || { necro_nurse "$component" "$failed_cmd" "${what_we_tried:-none}" "$is_critical"; return $?; }
    if [[ "$failure_type" == "yay" ]]; then
        what_we_tried+="[pacman fallback] "
        local pkg_name
        pkg_name=$(echo "$failed_cmd" | awk '{print $NF}')
        if [[ -n "$pkg_name" ]] && pacman -Si "$pkg_name" &>/dev/null; then
            if timeout "$NECRO_TRIAGE_TIMEOUT" sudo pacman -S --needed --noconfirm "$pkg_name" 2>/dev/null; then
                necro_log "OK" "$component" "pacman fallback succeeded  //  $pkg_name"
                return 0
            fi
        fi
    fi

    # ── CHECK 3: binary in PATH ──
    _necro_triage_check || { necro_nurse "$component" "$failed_cmd" "${what_we_tried:-none}" "$is_critical"; return $?; }
    what_we_tried+="[path hunt] "
    local bin_name
    bin_name=$(echo "$failed_cmd" | awk '{print $1}')
    if ! command -v "$bin_name" &>/dev/null; then
        local bin_path
        bin_path=$(find /usr/bin /usr/local/bin "$HOME/.local/bin" -name "$bin_name" 2>/dev/null | head -1)
        if [[ -n "$bin_path" ]]; then
            export PATH="$PATH:$(dirname "$bin_path")"
            if timeout "$NECRO_TRIAGE_TIMEOUT" bash -c "$failed_cmd" 2>/dev/null; then
                necro_log "OK" "$component" "Recovered after PATH fix  //  $bin_path"
                return 0
            fi
        fi
    fi

    necro_log "FUBAR" "$component" "All triage routes exhausted  //  tried: $what_we_tried"
    necro_nurse "$component" "$failed_cmd" "$what_we_tried" "$is_critical"
    return $?
}


# ════════════════════════════════════════════════════════════
# NECRO_PKG / NECRO_PKG_CRITICAL
# ════════════════════════════════════════════════════════════
necro_pkg() {
    local component="$1"; shift
    local pkgs=("$@")

    if sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>&1; then
        necro_log "OK" "$component" "pacman: ${pkgs[*]}"
        print_ok "${component}  ${DG}//  packages installed${NC}"
    else
        necro_log "FAIL" "$component" "pacman failed: ${pkgs[*]}"
        print_err "${component}  //  pacman failed — engaging triage"
        necro_triage "$component" "sudo pacman -S --needed --noconfirm ${pkgs[*]}" "pacman" "false" || true
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
        necro_triage "$component" "sudo pacman -S --needed --noconfirm ${pkgs[*]}" "pacman" "critical"
    fi
}


# ════════════════════════════════════════════════════════════
# NECRO_YAY / NECRO_YAY_CRITICAL
# ════════════════════════════════════════════════════════════
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
        necro_triage "$component" "yay -S --needed --noconfirm ${pkgs[*]}" "yay" "false" || true
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
        necro_triage "$component" "yay -S --needed --noconfirm ${pkgs[*]}" "yay" "critical"
    fi
}


# ════════════════════════════════════════════════════════════
# NECRO_GROUP_INSTALL
# ════════════════════════════════════════════════════════════
necro_group_install() {
    local group_label="$1"
    local component_id="$2"
    local pkg_manager="$3"
    shift 3
    local pkgs=("$@")

    local is_critical="false"
    [[ "$pkg_manager" == *"_critical" ]] && is_critical="true"

    necro_tui_stage_set "$component_id" "ACTIVE" 2>/dev/null || true

    (( NECRO_STAGE_CURRENT++ )) || true
    local stage_tag=""
    (( NECRO_STAGE_TOTAL > 0 )) && stage_tag="  //  STAGE ${NECRO_STAGE_CURRENT}/${NECRO_STAGE_TOTAL}"

    echo ""
    echo -e "  ${G}${B}  ┌─ ${group_label}${stage_tag} ─────────────────────────────────${NC}"
    for pkg in "${pkgs[@]}"; do echo -e "  ${DG}  │  · ${pkg}${NC}"; done
    echo -e "  ${G}${B}  └──────────────────────────────────────────────${NC}"
    echo ""

    local group_answer
    if ! command -v gum &>/dev/null || [[ ! -t 0 ]]; then
        group_answer="timeout"
        print_info "TTY mode  //  auto-confirming: ${group_label}"
    else
        group_answer=$(
            timeout "${NECRO_NURSE_TIMEOUT:-10}" \
            gum choose \
                --header="  Install group: ${group_label}?" \
                --header.foreground="2" \
                --cursor.foreground="2" \
                --selected.foreground="2" \
                --item.foreground="7" \
                "  YES — INSTALL ALL  " \
                "  NO  — LET ME CHOOSE  " \
            2>/dev/null
        ) || group_answer="timeout"
    fi

    if [[ "$group_answer" == "timeout" || "$group_answer" == *"YES"* ]]; then
        necro_log "INFO" "$component_id" "Group install: ${group_label}  //  all packages"
        _necro_group_do_install "$component_id" "$pkg_manager" "${pkgs[@]}"
        return $?
    fi

    echo ""
    print_info "Select packages  ${DG}//  SPACE=toggle  ENTER=confirm${NC}"
    echo ""

    local selected
    selected=$(
        printf '%s\n' "${pkgs[@]}" | \
        gum choose --no-limit \
            --selected="$(printf '%s,' "${pkgs[@]}")" \
            --header="  ${group_label}  —  deselect what you don't want" \
            --header.foreground="2" \
            --cursor.foreground="2" \
            --selected.foreground="2" \
            --item.foreground="8" \
        2>/dev/null
    )

    if [[ -z "$selected" ]]; then
        if [[ "$is_critical" == "true" ]]; then
            necro_log "CRIT" "$component_id" "Critical group skipped: ${group_label}"
            necro_tui_stage_set "$component_id" "FAIL" 2>/dev/null || true
            necro_critical_failure "$component_id" "group install: ${group_label}" \
                "operator declined all packages"
        else
            necro_log "SKIP" "$component_id" "Group skipped: ${group_label}  //  ${pkgs[*]}"
            necro_tui_stage_set "$component_id" "SKIP" 2>/dev/null || true
            print_skip "${group_label}  //  skipped by operator"
        fi
        return 0
    fi

    local selected_pkgs=()
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && selected_pkgs+=("$(echo "$pkg" | xargs)")
    done <<< "$selected"

    necro_log "INFO" "$component_id" "Group partial: ${group_label}  //  ${selected_pkgs[*]}"
    _necro_group_do_install "$component_id" "$pkg_manager" "${selected_pkgs[@]}"
    return $?
}

_necro_group_do_install() {
    local component_id="$1"
    local pkg_manager="$2"
    shift 2
    local pkgs=("$@")
    local result=0

    case "$pkg_manager" in
        pacman_critical) necro_pkg_critical "$component_id" "${pkgs[@]}" || result=$? ;;
        pacman)          necro_pkg          "$component_id" "${pkgs[@]}" || result=$? ;;
        yay_critical)    necro_yay_critical "$component_id" "${pkgs[@]}" || result=$? ;;
        yay)             necro_yay          "$component_id" "${pkgs[@]}" || result=$? ;;
        *)
            print_err "necro_group_install: unknown pkg_manager '${pkg_manager}'"
            necro_log "FAIL" "$component_id" "Unknown pkg_manager: ${pkg_manager}"
            necro_tui_stage_set "$component_id" "FAIL" 2>/dev/null || true
            return 1
            ;;
    esac

    if (( result == 0 )); then
        necro_tui_stage_set "$component_id" "OK" 2>/dev/null || true
    else
        necro_tui_stage_set "$component_id" "FAIL" 2>/dev/null || true
    fi
    return $result
}


# ════════════════════════════════════════════════════════════
# NECRO_POST_INSTALL_REPORT
# ════════════════════════════════════════════════════════════
necro_post_install_report() {
    local log="$NECRO_LOG_FILE"

    local skipped_lines=()
    while IFS= read -r line; do
        skipped_lines+=("$line")
    done < <(grep -E "\[(SKIP |FAIL |FUBAR|NURSE|CRIT )\]" "$log" 2>/dev/null)

    local report=""
    local skip_count="${#skipped_lines[@]}"

    if (( skip_count == 0 )); then
        report="  All stages completed without incident.\n\n  The tomb world is fully operational.\n  No skipped components. No outstanding faults."
    else
        report="  ${skip_count} stage(s) skipped or failed.\n\n"
        report+="  ── SKIPPED / FAILED STAGES ─────────────────────────────────\n\n"
        for line in "${skipped_lines[@]}"; do
            local level component reason
            level=$(echo "$line"     | grep -oP '(?<=\[)\w+(?=\s*\])' | head -1)
            component=$(echo "$line" | awk '{print $3}')
            reason=$(echo "$line"    | cut -d' ' -f4-)
            report+="  [${level}]  ${component}\n        ${reason}\n\n"
        done
        report+="  ── RECOMMENDED ACTION ──────────────────────────────────────\n\n"
        report+="  · Log out or reboot, then re-run the installer.\n\n"
        report+="  · Arch Wiki: https://wiki.archlinux.org\n\n"
        report+="  · Full log: ${log}"
    fi

    while true; do
        clear
        echo ""
        echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗"
        echo -e "  ║   NECRODERMIS — POST-INSTALLATION REPORT                     ║"
        echo -e "  ║   AWAKENING SEQUENCE COMPLETE  //  TOMB WORLD DIAGNOSTIC      ║"
        echo -e "  ╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${G}  ✓  Successful:${NC}  ${NECRO_OK_COUNT}"
        echo -e "  ${Y}  ·  Skipped:${NC}    ${NECRO_SKIP_COUNT}"
        echo -e "  ${R}  ✗  Failed:${NC}     ${NECRO_FAIL_COUNT}"
        echo ""
        echo -e "${DG}  ────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "$report" | while IFS= read -r rline; do echo -e "  ${DG}${rline}${NC}"; done
        echo ""
        echo -e "${DG}  ────────────────────────────────────────────────────────────${NC}"
        echo ""

        local choice
        if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
            choice=$(gum choose \
                --header="  NEXT DIRECTIVE  //  the tomb awaits your command" \
                --header.foreground="2" \
                --cursor.foreground="2" \
                --selected.foreground="2" \
                --item.foreground="7" \
                "  REBOOT NOW         //  recommended — apply all changes cleanly" \
                "  LOG OUT            //  return to login screen" \
                "  OPEN ARCH WIKI     //  https://wiki.archlinux.org" \
                "  CLOSE              //  dismiss and continue" \
            2>/dev/null) || choice="CLOSE"
        else
            echo -e "  ${G}  [R]${NC} Reboot   ${G}[L]${NC} Log out   ${G}[W]${NC} Arch Wiki   ${G}[C]${NC} Close"
            echo ""
            read -rp "  → " tty_choice
            case "${tty_choice,,}" in
                r) choice="REBOOT" ;; l) choice="LOGOUT" ;;
                w) choice="WIKI"   ;; *) choice="CLOSE"  ;;
            esac
        fi

        case "$choice" in
            *"REBOOT"*)
                print_info "Rebooting..."
                sleep 2; sudo reboot ;;
            *"LOG OUT"* | *"LOGOUT"*)
                print_info "Logging out..."
                sleep 2
                command -v loginctl &>/dev/null && loginctl terminate-user "$USER" \
                    || pkill -KILL -u "$USER" ;;
            *"ARCH WIKI"* | *"WIKI"*)
                if command -v xdg-open &>/dev/null; then
                    xdg-open "https://wiki.archlinux.org" &>/dev/null &
                else
                    echo -e "  ${G}  https://wiki.archlinux.org${NC}"
                fi
                read -rp "  Press ENTER to return..." _
                continue ;;
            *)
                print_info "Report dismissed  //  the tomb stands ready"
                echo ""
                break ;;
        esac
        break
    done
}
