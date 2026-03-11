#!/usr/bin/env bash
# Necrodermis — scripts/functions/firewall.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_firewall

install_firewall() {
    print_section "FIREWALL  //  PERIMETER DEFENCE PROTOCOL"

    # Install ufw if missing
    if ! command -v ufw &>/dev/null; then
        print_info "ufw not detected  //  dispatching scarabs to acquire..."
        sudo pacman -S --needed ufw --noconfirm
    else
        print_ok "ufw already present  ${DG}//  skipping install${NC}"
    fi

    # Detect LAN subnet from default route
    local LAN_SUBNET
    LAN_SUBNET=$(ip route | awk '/^[0-9]/ && !/default/ {print $1}' | head -1)
    if [ -z "$LAN_SUBNET" ]; then
        LAN_SUBNET="10.0.0.0/24"
        print_info "Could not detect LAN subnet  //  defaulting to $LAN_SUBNET"
        print_info "Edit /etc/ufw/before.rules if your network range differs"
    else
        print_ok "LAN subnet detected  ${DG}//  $LAN_SUBNET${NC}"
    fi

    # Reset ufw to clean slate
    sudo ufw --force reset

    # ── DEFAULT POLICIES ──
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw default allow forward
    print_ok "Default policies set  ${DG}//  deny incoming // allow outgoing${NC}"

    # ── LOOPBACK ──
    sudo ufw allow in on lo
    sudo ufw deny in from 127.0.0.0/8
    sudo ufw deny in from ::1
    print_ok "Loopback rules set  ${DG}//  localhost traffic permitted${NC}"

    # ── LIBVIRT / KVM (virbr0 — VM networking) ──
    sudo ufw allow in on virbr0
    sudo ufw allow out on virbr0
    sudo ufw route allow in on virbr0
    sudo ufw route allow out on virbr0
    print_ok "virbr0 permitted  ${DG}//  KVM VM networking active${NC}"

    # ── STEAM (scoped to LAN — Remote Play) ──
    sudo ufw allow from "$LAN_SUBNET" to any port 27036 proto tcp comment "Steam Remote Play TCP"
    sudo ufw allow from "$LAN_SUBNET" to any port 27036 proto udp comment "Steam Remote Play UDP"
    print_ok "Steam Remote Play armed  ${DG}//  LAN only ($LAN_SUBNET)${NC}"

    # ── SUNSHINE / MOONLIGHT (scoped to LAN) ──
    sudo ufw allow from "$LAN_SUBNET" to any port 47984 proto tcp comment "Sunshine HTTPS"
    sudo ufw allow from "$LAN_SUBNET" to any port 47989 proto tcp comment "Sunshine HTTP"
    sudo ufw allow from "$LAN_SUBNET" to any port 48010 proto tcp comment "Sunshine RTSP"
    sudo ufw allow from "$LAN_SUBNET" to any port 47998 proto udp comment "Sunshine video"
    sudo ufw allow from "$LAN_SUBNET" to any port 47999 proto udp comment "Sunshine control"
    sudo ufw allow from "$LAN_SUBNET" to any port 48000 proto udp comment "Sunshine audio"
    sudo ufw allow from "$LAN_SUBNET" to any port 48010 proto udp comment "Sunshine mic"
    print_ok "Sunshine/Moonlight armed  ${DG}//  LAN only ($LAN_SUBNET)${NC}"

    # ── TRANSMISSION (BitTorrent) ──
    sudo ufw allow 59480/tcp comment "Transmission TCP"
    sudo ufw allow 59480/udp comment "Transmission UDP"
    sudo ufw allow from "$LAN_SUBNET" to any port 6771 proto udp comment "Transmission LPD"
    print_ok "Transmission armed  ${DG}//  peer port open // LPD LAN only${NC}"

    # ── mDNS (local network discovery — Avahi, Chromecasts, etc.) ──
    sudo ufw allow in from "$LAN_SUBNET" to any port 5353 proto udp comment "mDNS LAN"
    print_ok "mDNS permitted  ${DG}//  LAN only${NC}"

    # ── BLOCK LLMNR (minor info leak — no practical use on desktop) ──
    sudo ufw deny 5355/tcp comment "Block LLMNR"
    sudo ufw deny 5355/udp comment "Block LLMNR"
    print_ok "LLMNR blocked  ${DG}//  info leak sealed${NC}"

    # ── RATE LIMIT SSH (not enabled, but armed if you ever turn it on) ──
    sudo ufw limit 22/tcp comment "SSH rate limit"
    print_ok "SSH rate limit armed  ${DG}//  SSH itself is not enabled${NC}"

    # ── ENABLE ──
    sudo ufw --force enable
    sudo systemctl enable ufw
    sudo systemctl start ufw

    print_ok "Perimeter defence online  ${DG}//  ufw active and enabled at boot${NC}"
    echo ""
    print_info "Current ruleset:"
    sudo ufw status numbered
    echo ""
    print_info "To open additional ports, see the Necrodermis README — FIREWALL section"
    print_info "Or run: sudo ufw allow <port>/<proto> comment \"description\""
}
