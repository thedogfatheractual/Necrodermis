#!/usr/bin/env bash
# Necrodermis — scripts/functions/hardening.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_hardening

install_hardening() {
    print_section "SYSTEM HARDENING  //  TOMB WORLD SECURITY PROTOCOLS"

    # ── SYSCTL — KERNEL HARDENING ──
    print_info "Applying kernel parameters  //  stand by..."

    sudo tee /etc/sysctl.d/99-necrodermis-hardening.conf > /dev/null <<'EOF'
# ════════════════════════════════════════════════════════════
# NECRODERMIS — KERNEL HARDENING
# Applied by Necrodermis installer — safe to remove if needed
# ════════════════════════════════════════════════════════════

# ── NETWORK ──
# Disable IP forwarding (this is a workstation, not a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Ignore ICMP redirects (prevents route hijacking)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Ignore ICMP broadcast (smurf attack mitigation)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Log suspicious packets (martians — packets with impossible source addresses)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Reverse path filtering — drop packets that don't make sense
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# ── KERNEL ──
# Restrict dmesg to root only (hides hardware info from unprivileged users)
kernel.dmesg_restrict = 1

# Restrict kernel pointer exposure in /proc (hardens against info leaks)
kernel.kptr_restrict = 2

# Restrict ptrace — processes can only trace their own children
# (set to 1 not 3 — value 3 breaks some debuggers and game anti-cheat)
kernel.yama.ptrace_scope = 1

# Restrict kernel logs to root
kernel.printk = 3 3 3 3

# ── MEMORY ──
# Disable core dumps (stops sensitive memory hitting disk)
kernel.core_pattern = |/bin/false
fs.suid_dumpable = 0

# Randomise memory layout (ASLR — should already be on, making it explicit)
kernel.randomize_va_space = 2
EOF

    sudo sysctl --system > /dev/null 2>&1
    print_ok "Kernel parameters applied  ${DG}//  /etc/sysctl.d/99-necrodermis-hardening.conf${NC}"

    # ── CORE DUMPS — SYSTEMD SIDE ──
    sudo mkdir -p /etc/systemd/coredump.conf.d
    sudo tee /etc/systemd/coredump.conf.d/necrodermis.conf > /dev/null <<'EOF'
[Coredump]
Storage=none
ProcessSizeMax=0
EOF
    print_ok "Core dumps disabled  ${DG}//  sensitive memory stays off disk${NC}"

    # ── DISABLE LLMNR + MULTICAST DNS IN RESOLVED ──
    # We allow mDNS in ufw for LAN discovery but disable LLMNR entirely
    sudo mkdir -p /etc/systemd/resolved.conf.d
    sudo tee /etc/systemd/resolved.conf.d/necrodermis.conf > /dev/null <<'EOF'
[Resolve]
LLMNR=no
MulticastDNS=resolve
EOF
    sudo systemctl restart systemd-resolved 2>/dev/null || true
    print_ok "LLMNR disabled  ${DG}//  mDNS set to resolve-only${NC}"

    # ── LOCK ROOT ACCOUNT ──
    echo ""
    echo -e "${Y}  Locking root account — you will still have full sudo access.${NC}"
    echo -e "${Y}  Direct root login via console or SSH will be disabled.${NC}"
    echo -e "${Y}  To reverse: sudo passwd -u root${NC}"
    echo ""
    if confirm "Lock root account?"; then
        sudo passwd -l root
        print_ok "Root account locked  ${DG}//  sudo access unaffected${NC}"
    else
        print_skip "Root account lock"
    fi

    # ── RESTRICT /proc (hidepid) ──
    echo ""
    echo -e "${Y}  hidepid — restricts /proc so users can only see their own processes.${NC}"
    echo -e "${Y}  On a single-user machine this is low risk.${NC}"
    echo -e "${Y}  If anything acts weird, remove the hidepid line from /etc/fstab.${NC}"
    echo ""
    if confirm "Enable hidepid on /proc?"; then
        if ! grep -q "hidepid" /etc/fstab; then
            echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" \
                | sudo tee -a /etc/fstab > /dev/null
            print_ok "hidepid enabled  ${DG}//  takes effect after reboot${NC}"
        else
            print_info "hidepid already present in /etc/fstab  //  skipping"
        fi
    else
        print_skip "hidepid"
    fi

    # ── UMASK ──
    # Add umask 027 to fish config if not already set
    if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
        if ! grep -q "umask 027" "$CONFIG_DIR/fish/config.fish"; then
            echo "" >> "$CONFIG_DIR/fish/config.fish"
            echo "# Necrodermis — restrict default file permissions" >> "$CONFIG_DIR/fish/config.fish"
            echo "umask 027" >> "$CONFIG_DIR/fish/config.fish"
            print_ok "umask 027 set  ${DG}//  new files not world-readable by default${NC}"
        else
            print_info "umask 027 already set  //  skipping"
        fi
    fi

    # ── UFW LOGGING ──
    if command -v ufw &>/dev/null; then
        sudo ufw logging low
        print_ok "ufw logging enabled  ${DG}//  denied packets logged to /var/log/ufw.log${NC}"
    fi

    echo ""
    print_ok "Hardening complete  ${DG}//  reboot recommended for all changes to take effect${NC}"
    print_info "Kernel params: /etc/sysctl.d/99-necrodermis-hardening.conf"
    print_info "Core dumps:    /etc/systemd/coredump.conf.d/necrodermis.conf"
    print_info "DNS:           /etc/systemd/resolved.conf.d/necrodermis.conf"
    print_info "To reverse root lock: sudo passwd -u root"
    print_info "To reverse hidepid:   remove hidepid line from /etc/fstab"
}
