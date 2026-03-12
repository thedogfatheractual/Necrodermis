#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — CANOPTEK VISUAL INTERFACE
# scripts/necro-tui.sh
#
# Layout (fullscreen):
#   ┌───────────────┬─────────────────────┬───────────────┐
#   │  LOG TAIL     │    LIVE OUTPUT      │  STAGE STATUS │
#   │  errors +     │    pacman / yay     │  tick list    │
#   │  events       │    raw output       │  live update  │
#   ├───────────────┴─────────────────────┴───────────────┤
#   │  CPU ████░ 34%    RAM ████░ 5.1/8GB    DISK ███░ 47%│
#   └─────────────────────────────────────────────────────┘
#   Top tmux bar: version // current stage // clock
#
# Internal flags — do not call directly:
#   --tui-left-pane      log tail (left)
#   --tui-right-pane     stage status (right)
#   --tui-resource-bar   bottom resource monitor
#   --tui-inside         installer running inside TUI
# ════════════════════════════════════════════════════════════

NECRO_TUI_SESSION="necrodermis"
NECRO_TUI_STATE="/tmp/necrodermis-tui"
NECRO_TUI_STAGES_FILE="$NECRO_TUI_STATE/stages"
NECRO_TUI_CURRENT_FILE="$NECRO_TUI_STATE/current"
NECRO_TUI_START_FILE="$NECRO_TUI_STATE/start_time"

G='\033[0;32m'
DG='\033[2;32m'
R='\033[0;31m'
Y='\033[0;33m'
B='\033[1m'
NC='\033[0m'
CLS='\033[2J\033[H'


# ════════════════════════════════════════════════════════════
# NECRO_TUI_INIT
# Registers the stage manifest. Call once at start of install.
# Usage: necro_tui_init "id|Label" "id|Label" ...
# ════════════════════════════════════════════════════════════
necro_tui_init() {
    mkdir -p "$NECRO_TUI_STATE"
    rm -f "$NECRO_TUI_STAGES_FILE" "$NECRO_TUI_CURRENT_FILE"

    for entry in "$@"; do
        local id="${entry%%|*}"
        local label="${entry##*|}"
        echo "PENDING|${id}|${label}" >> "$NECRO_TUI_STAGES_FILE"
    done

    date +%s > "$NECRO_TUI_START_FILE"
    echo "INITIALISING" > "$NECRO_TUI_CURRENT_FILE"
}


# ════════════════════════════════════════════════════════════
# NECRO_TUI_STAGE_SET
# Updates a stage status in the manifest.
# Usage: necro_tui_stage_set "component-id" "ACTIVE|OK|FAIL|SKIP"
# ════════════════════════════════════════════════════════════
necro_tui_stage_set() {
    local id="$1"
    local status="$2"
    [[ ! -f "$NECRO_TUI_STAGES_FILE" ]] && return 0

    local tmp
    tmp=$(mktemp)
    while IFS='|' read -r st sid slabel; do
        if [[ "$sid" == "$id" ]]; then
            echo "${status}|${sid}|${slabel}"
        else
            echo "${st}|${sid}|${slabel}"
        fi
    done < "$NECRO_TUI_STAGES_FILE" > "$tmp"
    mv "$tmp" "$NECRO_TUI_STAGES_FILE"

    [[ "$status" == "ACTIVE" ]] && echo "$id" > "$NECRO_TUI_CURRENT_FILE"
}


# ════════════════════════════════════════════════════════════
# NECRO_TUI_DONE
# Signals all panes that install is complete.
# ════════════════════════════════════════════════════════════
necro_tui_done() {
    echo "DONE" > "$NECRO_TUI_CURRENT_FILE" 2>/dev/null || true
}


# ════════════════════════════════════════════════════════════
# _NECRO_TUI_RIGHT_PANE — stage status list (right panel)
# Redraws every 0.5s from the stages manifest.
# ════════════════════════════════════════════════════════════
_necro_tui_right_pane() {
    printf "${CLS}"
    echo ""
    echo -e "${G}${B}  STAGE STATUS${NC}"
    echo -e "${DG}  ─────────────────────────────${NC}"
    echo ""
    echo -e "${DG}  ·  awaiting installer...${NC}"

    while [[ ! -f "$NECRO_TUI_STAGES_FILE" ]]; do
        sleep 0.3
    done

    while true; do
        local total=0 done_count=0
        local lines=()

        while IFS='|' read -r status id label; do
            (( total++ ))
            local icon color
            case "$status" in
                ACTIVE)  icon="►"; color="${G}${B}" ; (( done_count++ )) ;;
                OK)      icon="✓"; color="${G}"     ; (( done_count++ )) ;;
                FAIL)    icon="✗"; color="${R}"     ; (( done_count++ )) ;;
                SKIP)    icon="·"; color="${Y}"     ; (( done_count++ )) ;;
                PENDING) icon="·"; color="${DG}"    ;;
                *)       icon="·"; color="${DG}"    ;;
            esac
            lines+=("${color}  ${icon}  ${label}${NC}")
        done < "$NECRO_TUI_STAGES_FILE"

        local elapsed="00:00"
        if [[ -f "$NECRO_TUI_START_FILE" ]]; then
            local start now
            start=$(cat "$NECRO_TUI_START_FILE")
            now=$(date +%s)
            elapsed=$(printf "%02d:%02d" \
                $(( (now - start) / 60 )) \
                $(( (now - start) % 60 )))
        fi

        printf "${CLS}"
        echo ""
        echo -e "${G}${B}  STAGE STATUS${NC}  ${DG}[${done_count}/${total}]${NC}"
        echo -e "${DG}  ─────────────────────────────${NC}"
        echo ""
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo ""
        echo -e "${DG}  ─────────────────────────────${NC}"
        echo -e "${DG}  Elapsed: ${elapsed}${NC}"

        if [[ "$(cat "$NECRO_TUI_CURRENT_FILE" 2>/dev/null)" == "DONE" ]]; then
            echo ""
            echo -e "${G}${B}  SEQUENCE COMPLETE${NC}"
            break
        fi

        sleep 0.5
    done

    read -rp "" _
}


# ════════════════════════════════════════════════════════════
# _NECRO_TUI_LEFT_PANE — install log tail (left panel)
# Follows NECRO_LOG_FILE with colour coding by level.
# ════════════════════════════════════════════════════════════
_necro_tui_left_pane() {
    local log="${NECRO_LOG_FILE:-$HOME/.local/share/necrodermis/install.log}"

    printf "${CLS}"
    echo ""
    echo -e "${G}${B}  INSTALL LOG${NC}"
    echo -e "${DG}  ─────────────────────────────${NC}"
    echo ""

    # Wait for log to exist
    while [[ ! -f "$log" ]]; do
        echo -e "${DG}  Waiting for log...${NC}"
        sleep 1
        printf "${CLS}"
        echo ""
        echo -e "${G}${B}  INSTALL LOG${NC}"
        echo -e "${DG}  ─────────────────────────────${NC}"
        echo ""
    done

    # Tail and colourize by level
    tail -f "$log" 2>/dev/null | while IFS= read -r line; do
        local color="${DG}"
        [[ "$line" =~ \[OK\]    ]] && color="${G}"
        [[ "$line" =~ \[SKIP\]  ]] && color="${Y}"
        [[ "$line" =~ \[FAIL\]  ]] && color="${R}"
        [[ "$line" =~ \[FUBAR\] ]] && color="${R}${B}"
        [[ "$line" =~ \[CRIT\]  ]] && color="${R}${B}"
        [[ "$line" =~ \[NURSE\] ]] && color="${Y}${B}"
        [[ "$line" =~ \[INFO\]  ]] && color="${DG}"
        echo -e "${color}  ${line}${NC}"
    done
}


# ════════════════════════════════════════════════════════════
# _NECRO_TUI_RESOURCE_BAR — bottom pane, resource monitor
# Updates every 2s. Reads from /proc — no external deps.
# ════════════════════════════════════════════════════════════
_necro_tui_resource_bar() {
    local bar_width=20

    _make_bar() {
        local pct="$1"
        local width="$2"
        local filled=$(( pct * width / 100 ))
        local empty=$(( width - filled ))
        local bar=""
        local i
        for (( i=0; i<filled; i++ )); do bar+="█"; done
        for (( i=0; i<empty;  i++ )); do bar+="░"; done
        echo "$bar"
    }

    _cpu_pct() {
        # Read two samples 0.8s apart, compute delta
        local s1 s2
        read -r _ u1 n1 s1_sys i1 _ < /proc/stat
        sleep 0.8
        read -r _ u2 n2 s2_sys i2 _ < /proc/stat
        local idle_d=$(( i2 - i1 ))
        local total_d=$(( (u2+n2+s2_sys+i2) - (u1+n1+s1_sys+i1) ))
        if (( total_d == 0 )); then echo 0; return; fi
        echo $(( 100 - (idle_d * 100 / total_d) ))
    }

    _mem_info() {
        local total_kb used_kb pct
        local mem_total mem_available
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        used_kb=$(( mem_total - mem_available ))
        pct=$(( used_kb * 100 / mem_total ))
        local used_gb total_gb
        used_gb=$(awk "BEGIN {printf \"%.1f\", $used_kb/1048576}")
        total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total/1048576}")
        echo "${pct}|${used_gb}|${total_gb}"
    }

    _disk_info() {
        local line
        line=$(df / --output=pcent,used,size -BG 2>/dev/null | tail -1)
        local pct used size
        pct=$(echo "$line" | awk '{print $1}' | tr -d '%')
        used=$(echo "$line" | awk '{print $2}' | tr -d 'G')
        size=$(echo "$line" | awk '{print $3}' | tr -d 'G')
        echo "${pct}|${used}|${size}"
    }

    while true; do
        local cpu_pct mem_pct mem_used mem_total disk_pct disk_used disk_size
        cpu_pct=$(_cpu_pct)

        IFS='|' read -r mem_pct mem_used mem_total <<< "$(_mem_info)"
        IFS='|' read -r disk_pct disk_used disk_size <<< "$(_disk_info)"

        local cpu_bar mem_bar disk_bar
        cpu_bar=$(_make_bar "$cpu_pct"  "$bar_width")
        mem_bar=$(_make_bar "$mem_pct"  "$bar_width")
        disk_bar=$(_make_bar "$disk_pct" "$bar_width")

        # Colour bars by usage — green <65, yellow 65-89, red 90+
        local cpu_col mem_col disk_col
        _bar_col() {
            local pct="$1"
            if   (( pct >= 90 )); then echo "${R}"
            elif (( pct >= 65 )); then echo "${Y}"
            else                       echo "${G}"
            fi
        }
        cpu_col=$(_bar_col "$cpu_pct")
        mem_col=$(_bar_col "$mem_pct")
        disk_col=$(_bar_col "$disk_pct")

        printf "${CLS}"
        printf "  ${G}${B}CPU${NC}  ${cpu_col}${cpu_bar}${NC}  %3d%%     " "$cpu_pct"
        printf "  ${G}${B}RAM${NC}  ${mem_col}${mem_bar}${NC}  %s/%s GB     " "$mem_used" "$mem_total"
        printf "  ${G}${B}DISK${NC}  ${disk_col}${disk_bar}${NC}  %s/%s GB  %d%%\n" \
            "$disk_used" "$disk_size" "$disk_pct"

        sleep 0.7
    done
}


# ════════════════════════════════════════════════════════════
# NECRO_TUI_LAUNCH
# Builds the tmux session and layout, then attaches.
# Called from install.sh when not already inside tmux.
# ════════════════════════════════════════════════════════════
necro_tui_launch() {
    local install_script="$1"
    shift
    local install_args=("$@")

    # Kill any stale session
    tmux kill-session -t "$NECRO_TUI_SESSION" 2>/dev/null || true

    local version="NECRODERMIS"
    local version_file
    version_file="$(dirname "$install_script")/VERSION"
    [[ -f "$version_file" ]] && version="NECRODERMIS  v$(cat "$version_file")"

    # Get full terminal dimensions
    local cols lines
    cols=$(tput cols)
    lines=$(tput lines)

    # Left and right side panes — each ~22% of width, centre gets the rest
    local side_w=$(( cols * 22 / 100 ))
    # Resource bar — 3 lines tall
    local res_h=3

    # New session — full terminal size
    tmux new-session -d -s "$NECRO_TUI_SESSION" \
        -x "$cols" -y "$lines"

    # ── Top status bar ──
    tmux set-option -t "$NECRO_TUI_SESSION" status on
    tmux set-option -t "$NECRO_TUI_SESSION" status-position top
    tmux set-option -t "$NECRO_TUI_SESSION" status-style "fg=colour2,bg=colour0,bold"
    tmux set-option -t "$NECRO_TUI_SESSION" status-left-length 80
    tmux set-option -t "$NECRO_TUI_SESSION" status-right-length 40
    tmux set-option -t "$NECRO_TUI_SESSION" status-left \
        "#[fg=colour2,bold]  ${version}  //  SAUTEKH DYNASTY  //  AWAKENING SEQUENCE  "
    tmux set-option -t "$NECRO_TUI_SESSION" status-right \
        "#[fg=colour2,bold]  NECRODERMIS  //  %H:%M:%S  "
    tmux set-option -t "$NECRO_TUI_SESSION" status-interval 1

    # ── Pane borders ──
    tmux set-option -t "$NECRO_TUI_SESSION" pane-border-style "fg=colour0"
    tmux set-option -t "$NECRO_TUI_SESSION" pane-active-border-style "fg=colour2"
    tmux set-option -t "$NECRO_TUI_SESSION" pane-border-lines heavy

    # ── Build layout ──
    # Start: one pane (pane 0) — will become centre (live output)
    # Split bottom for resource bar
    tmux split-window -t "$NECRO_TUI_SESSION:0.0" \
        -v -l "$res_h"

    # Split left from centre
    tmux split-window -t "$NECRO_TUI_SESSION:0.0" \
        -h -b -l "$side_w"

    # Split right from centre
    tmux split-window -t "$NECRO_TUI_SESSION:0.1" \
        -h -l "$side_w"

    # Pane map at this point:
    #   0.0 = left   (log tail)
    #   0.1 = centre (live install output)
    #   0.2 = right  (stage status)
    #   0.3 = bottom (resource bar)

    # ── Launch pane processes ──
    # Left — log tail
    tmux send-keys -t "$NECRO_TUI_SESSION:0.0" \
        "NECRO_LOG_FILE='${NECRO_LOG_FILE:-$HOME/.local/share/necrodermis/install.log}' \
         NECRO_TUI_STATE='${NECRO_TUI_STATE}' \
         bash '${install_script}' --tui-left-pane" Enter

    # Right — stage status
    tmux send-keys -t "$NECRO_TUI_SESSION:0.2" \
        "NECRO_TUI_STATE='${NECRO_TUI_STATE}' \
         bash '${install_script}' --tui-right-pane" Enter

    # Bottom — resource bar
    tmux send-keys -t "$NECRO_TUI_SESSION:0.3" \
        "bash '${install_script}' --tui-resource-bar" Enter

    # Centre — actual installer (focus here)
    tmux send-keys -t "$NECRO_TUI_SESSION:0.1" \
        "bash '${install_script}' --tui-inside ${install_args[*]}; tmux kill-session -t '${NECRO_TUI_SESSION}'" Enter

    tmux select-pane -t "$NECRO_TUI_SESSION:0.1"

    # Attach fullscreen
    tmux attach-session -t "$NECRO_TUI_SESSION"
}


# ════════════════════════════════════════════════════════════
# ENTRY POINT — flag dispatch
# ════════════════════════════════════════════════════════════
case "${1:-}" in
    --tui-left-pane)     _necro_tui_left_pane    ;;
    --tui-right-pane)    _necro_tui_right_pane   ;;
    --tui-resource-bar)  _necro_tui_resource_bar ;;
esac
