#!/usr/bin/env bash
# NECRODERMIS — scripts/necro-codex.sh
# Post-install tomb codex — final inscription after successful deployment

NECRO_VERSION="${NECRO_VERSION:-unknown}"

necro_codex() {
    local DG='\033[0;32m'
    local W='\033[1;37m'
    local DIM='\033[2m'
    local NC='\033[0m'

    clear
    echo -e "
${DG}  ╔══════════════════════════════════════════════════════════════════╗
  ║                                                                  ║
  ║   T H E   N E C R O D E R M I S   P R O T O C O L              ║
  ║                                                                  ║
  ╠══════════════════════════════════════════════════════════════════╣${NC}
  ║                                                                  ║
  ║  ${W}Tomb world conversion complete.${NC}                               ║
  ║  ${W}Version :${NC} $NECRO_VERSION                                           ║
  ║                                                                  ║
  ║  ${DIM}The living metal has been applied. Your system now bears        ║
  ║  the Necrodermis. All organic processes have been optimised.     ║
  ║  Canoptek constructs are standing by.${NC}                           ║
  ║                                                                  ║
${DG}  ╠══════════════════════════════════════════════════════════════════╣${NC}
  ║                                                                  ║
  ║  ${W}NEXT STEPS${NC}                                                     ║
  ║                                                                  ║
  ║    1. Reboot to complete awakening sequence                      ║
  ║       ${DG}systemctl reboot${NC}                                          ║
  ║                                                                  ║
  ║    2. SDDM login interface will be active on next boot           ║
  ║                                                                  ║
  ║    3. Run sitrep to confirm atmospheric sensors                  ║
  ║       ${DG}sitrep${NC}                                                    ║
  ║                                                                  ║
  ║    4. Source repository                                          ║
  ║       ${DG}https://github.com/thedogfatheractual/Necrodermis${NC}        ║
  ║                                                                  ║
${DG}  ╚══════════════════════════════════════════════════════════════════╝${NC}
"
}

necro_codex
