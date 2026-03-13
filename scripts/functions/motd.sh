#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/motd.sh
# Component: install_motd
# Operator briefing — security status + tomb world lore inscription

install_motd() {
    print_section "MOTD  //  OPERATOR BRIEFING INSCRIPTION"

    local MOTD_FILE="/etc/motd"
    local MOTD_SCRIPT="/etc/profile.d/necrodermis-motd.sh"

    # ── Static /etc/motd — shown by login managers ──
    sudo tee "$MOTD_FILE" > /dev/null <<'EOF'

  ╔══════════════════════════════════════════════════════════════╗
  ║  N E C R O D E R M I S  //  TOMB WORLD INTERFACE ACTIVE     ║
  ║  Canoptek systems nominal. Awaiting operator authentication. ║
  ╚══════════════════════════════════════════════════════════════╝

EOF

    # ── Dynamic profile.d script — runs on interactive shell login ──
    sudo tee "$MOTD_SCRIPT" > /dev/null <<'PROFILE'
#!/usr/bin/env bash
# NECRODERMIS — dynamic operator briefing
# Fires on every interactive login shell

[[ $- != *i* ]] && return
[[ -n "$NECRO_MOTD_SHOWN" ]] && return
export NECRO_MOTD_SHOWN=1

DG='\033[0;32m'
R='\033[0;31m'
Y='\033[0;33m'
W='\033[1;37m'
NC='\033[0m'

_host=$(hostname)
_kernel=$(uname -r)
_uptime=$(uptime -p 2>/dev/null | sed 's/up //')
_user=$(whoami)

# Firewall status
if command -v ufw &>/dev/null; then
    _ufw=$(sudo ufw status 2>/dev/null | awk 'NR==1{print $2}')
    [[ "$_ufw" == "active" ]] && _fw="${DG}ACTIVE${NC}" || _fw="${R}INACTIVE${NC}"
else
    _fw="${Y}ABSENT${NC}"
fi

# Weather from sitrep cache
_weather_cache="$HOME/.cache/sitrep/weather.json"
if [[ -f "$_weather_cache" ]]; then
    _wx=$(python3 -c "
import json
try:
    d = json.load(open('$_weather_cache'))
    print(d.get('condition','--') + '  ' + str(d.get('temp_c','--')) + 'C')
except:
    print('METAR unavailable')
" 2>/dev/null)
else
    _wx="no atmospheric data"
fi

echo -e "
${DG}  ╔══════════════════════════════════════════════════════════════╗
  ║  N E C R O D E R M I S  //  TOMB WORLD INTERFACE ACTIVE     ║
  ╠══════════════════════════════════════════════════════════════╣${NC}
  ║  ${W}OPERATOR${NC}   $_user@$_host
  ║  ${W}KERNEL  ${NC}   $_kernel
  ║  ${W}UPTIME  ${NC}   $_uptime
  ║  ${W}FIREWALL${NC}   $(echo -e $_fw)
  ║  ${W}SITREP  ${NC}   $_wx
${DG}  ╚══════════════════════════════════════════════════════════════╝${NC}
"
PROFILE

    sudo chmod +x "$MOTD_SCRIPT"
    print_ok "MOTD inscribed  ${DG}//  operator briefing active${NC}"
    print_info "Briefing fires on every interactive login shell"
}
