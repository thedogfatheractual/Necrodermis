#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# NECRODERMIS — CANOPTEK MAINTENANCE PROTOCOL
# scripts/necro-autoupdate.sh
#
# Runs on Hyprland login via exec-once.
# Syncs the tomb world with the greater network.
# Detects critical updates — prompts reboot if required.
# ════════════════════════════════════════════════════════════

G='\033[0;32m'
DG='\033[2;32m'
Y='\033[0;33m'
R='\033[0;31m'
B='\033[1m'
NC='\033[0m'

# Packages that warrant a reboot if updated
REBOOT_TRIGGERS=(
    linux
    linux-cachyos
    linux-cachyos-rc
    linux-lts
    linux-zen
    linux-hardened
    linux-firmware
    systemd
    systemd-libs
    glibc
    glibc-locales
    nvidia
    nvidia-dkms
    amdgpu
    mesa
    vulkan-radeon
    initramfs
)

clear
echo ""
echo -e "${G}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${G}${B}  ║   NECRODERMIS  //  CANOPTEK MAINTENANCE PROTOCOL            ║${NC}"
echo -e "${G}${B}  ║   SAUTEKH DYNASTY  //  TOMB WORLD SYNCHRONISATION           ║${NC}"
echo -e "${G}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${DG}  The tomb world is synchronising with the greater network.${NC}"
echo -e "${DG}  This window will close automatically when complete.${NC}"
echo -e "${DG}  No action required.${NC}"
echo ""
echo -e "${G}${B}  ─────────────────────────────────────────────────────────────${NC}"
echo ""

# Run update, capture output for reboot detection
UPDATE_LOG=$(mktemp)

if command -v yay &>/dev/null; then
    yay -Syyu --noconfirm --noprogressbar 2>&1 | tee "$UPDATE_LOG"
elif command -v pacman &>/dev/null; then
    echo -e "${Y}  yay unavailable — falling back to pacman${NC}"
    echo ""
    sudo pacman -Syyu --noconfirm --noprogressbar 2>&1 | tee "$UPDATE_LOG"
else
    echo -e "${R}  No package manager found — skipping synchronisation${NC}"
    rm -f "$UPDATE_LOG"
    sleep 3
    exit 1
fi

echo ""
echo -e "${G}${B}  ─────────────────────────────────────────────────────────────${NC}"
echo ""

# Check if any reboot-triggering packages were updated
REBOOT_NEEDED=false
REBOOT_PKGS=()

for pkg in "${REBOOT_TRIGGERS[@]}"; do
    if grep -qE "upgrading ${pkg}$|installing ${pkg}$|reinstalling ${pkg}$" "$UPDATE_LOG" 2>/dev/null; then
        REBOOT_NEEDED=true
        REBOOT_PKGS+=("$pkg")
    fi
done

rm -f "$UPDATE_LOG"

if [[ "$REBOOT_NEEDED" == "true" ]]; then
    echo ""
    echo -e "${Y}${B}  ╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${Y}${B}  ║                                                              ║${NC}"
    echo -e "${Y}${B}  ║   STRUCTURAL RECALIBRATION REQUIRED                         ║${NC}"
    echo -e "${Y}${B}  ║   Critical tomb world components were updated.              ║${NC}"
    echo -e "${Y}${B}  ║   A reboot is recommended to finalise integration.          ║${NC}"
    echo -e "${Y}${B}  ║                                                              ║${NC}"
    echo -e "${Y}${B}  ╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${Y}  Updated critical components:${NC}"
    for pkg in "${REBOOT_PKGS[@]}"; do
        echo -e "  ${DG}  ·  ${pkg}${NC}"
    done
    echo ""

    if command -v gum &>/dev/null; then
        choice=$(gum choose \
            --header="  CANOPTEK DIRECTIVE  //  reboot to complete integration?" \
            --header.foreground="3" \
            --cursor.foreground="2" \
            --selected.foreground="2" \
            --item.foreground="7" \
            "  REBOOT NOW     //  recommended — finalise canoptek conversion" \
            "  LATER          //  I know what I'm doing" \
        2>/dev/null) || choice="LATER"
    else
        echo -e "  ${G}  [R]${NC} Reboot now   ${G}[L]${NC} Later"
        echo ""
        read -rp "  → " raw_choice
        case "${raw_choice,,}" in
            r) choice="REBOOT" ;;
            *) choice="LATER"  ;;
        esac
    fi

    case "$choice" in
        *"REBOOT"*)
            echo ""
            echo -e "${G}${B}  Initiating reboot sequence...${NC}"
            sleep 2
            systemctl reboot
            ;;
        *)
            echo ""
            echo -e "${DG}  Reboot deferred. The tomb remembers.${NC}"
            sleep 3
            ;;
    esac
else
    echo -e "${G}${B}  ✓  Synchronisation complete. Tomb world is current.${NC}"
    echo ""
    sleep 2
fi
