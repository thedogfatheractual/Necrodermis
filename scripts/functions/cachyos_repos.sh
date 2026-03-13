#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/cachyos_repos.sh
# Extracted from monolith install-OGSHELL.sh
# Component: install_cachyos_repos

install_cachyos_repos() {
    print_section "CACHYOS REPOSITORIES  //  OPTIMISED PACKAGE MATRIX"

    # ── CPU LEVEL CHECK ──
    local cpu_level
    cpu_level="$(detect_cpu_level)"
    print_info "CPU microarchitecture level: x86-64-${cpu_level}"

    if [ "$cpu_level" = "v1" ] || [ "$cpu_level" = "v2" ]; then
        echo ""
        echo -e "  ${R}  INCOMPATIBLE HARDWARE DETECTED${NC}"
        echo -e "  ${Y}  CachyOS repositories require x86-64-v3 or higher.${NC}"
        echo -e "  ${Y}  Your CPU is x86-64-${cpu_level} — optimised packages will not run.${NC}"
        echo -e "  ${Y}  Skipping CachyOS repo installation.${NC}"
        echo ""
        print_info "Affected CPUs: Intel pre-Haswell, AMD pre-Ryzen, most laptop CPUs pre-2015"
        print_info "If you believe this is wrong: grep avx2 /proc/cpuinfo"
        return 0
    fi

    echo ""
    echo -e "${G}  CPU is x86-64-${cpu_level} — compatible with CachyOS repositories.${NC}"
    echo ""
    echo -e "${DG}  CachyOS repositories provide packages compiled with superior optimisation${NC}"
    echo -e "${DG}  flags (LTO, PGO, x86-64-v3/v4). On compatible hardware this means${NC}"
    echo -e "${DG}  measurably better performance across the entire system.${NC}"
    echo ""
    echo -e "${DG}  This will add the CachyOS keyring, mirrorlist, and pacman repo entries.${NC}"
    echo -e "${DG}  The CachyOS kernel and gaming meta will be offered separately.${NC}"
    echo ""

    if ! confirm "Add CachyOS repositories?"; then
        print_skip "CachyOS repositories"
        return 0
    fi

    # ── KEYRING + MIRRORLIST ──
    # Run in a subshell so errors don't kill the parent script via set -e
    print_info "Installing CachyOS keyring and mirrorlist..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local cachyos_ok=1

    # Keyring
    if curl -fsSL "https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-latest-any.pkg.tar.zst" \
            -o "$tmp_dir/cachyos-keyring.pkg.tar.zst" 2>/dev/null; then
        if ! sudo pacman -U "$tmp_dir/cachyos-keyring.pkg.tar.zst" --noconfirm 2>/dev/null; then
            print_err "Keyring install failed — trying keyserver fallback..."
            sudo pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com 2>/dev/null || true
            sudo pacman-key --lsign-key F3B607488DB35A47 2>/dev/null || true
        else
            print_ok "CachyOS keyring installed${NC}"
        fi
    else
        print_err "Could not fetch CachyOS keyring — check network connection"
        print_info "CachyOS repo installation aborted — no changes made to pacman.conf"
        rm -rf "$tmp_dir"
        cachyos_ok=0
    fi

    # Mirrorlist
    if [ "$cachyos_ok" -eq 1 ]; then
        if curl -fsSL "https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-latest-any.pkg.tar.zst" \
                -o "$tmp_dir/cachyos-mirrorlist.pkg.tar.zst" 2>/dev/null; then
            if ! sudo pacman -U "$tmp_dir/cachyos-mirrorlist.pkg.tar.zst" --noconfirm 2>/dev/null; then
                print_err "Mirrorlist install failed"
                cachyos_ok=0
            else
                print_ok "CachyOS mirrorlist installed${NC}"
            fi
        else
            print_err "Could not fetch CachyOS mirrorlist"
            cachyos_ok=0
        fi
    fi

    rm -rf "$tmp_dir"

    if [ "$cachyos_ok" -eq 0 ]; then
        print_err "CachyOS repo setup failed — pacman.conf was NOT modified"
        print_info "You can retry manually: yay -S cachyos-keyring cachyos-mirrorlist"
        return 0
    fi

    # ── PACMAN.CONF ENTRIES ──
    if grep -q "\[cachyos\]" /etc/pacman.conf; then
        print_info "CachyOS repo entries already present in /etc/pacman.conf  //  skipping"
    else
        print_info "Adding CachyOS repo entries to /etc/pacman.conf..."

        # Backup pacman.conf before touching it
        sudo cp /etc/pacman.conf /etc/pacman.conf.necrodermis-backup

        if [ "$cpu_level" = "v4" ]; then
            sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

# ── CachyOS Repositories (added by Necrodermis) ──
[cachyos-v4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-core-v4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-extra-v4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
EOF
        else
            # v3
            sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

# ── CachyOS Repositories (added by Necrodermis) ──
[cachyos-v3]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-core-v3]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-extra-v3]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
EOF
        fi

        print_ok "CachyOS repos added to /etc/pacman.conf  ${DG}//  x86-64-${cpu_level} tier${NC}"
    fi

    # Sync — if this fails, restore pacman.conf and bail gracefully
    if ! sudo pacman -Sy 2>/dev/null; then
        print_err "pacman sync failed — restoring pacman.conf from backup"
        sudo cp /etc/pacman.conf.necrodermis-backup /etc/pacman.conf
        sudo pacman -Sy 2>/dev/null || true
        print_info "pacman.conf restored  //  CachyOS repos not active"
        return 0
    fi
    print_ok "Package database synchronised  ${DG}//  CachyOS repos online${NC}"

    # ── CACHYOS KERNEL ──
    echo ""
    echo -e "${DG}  The CachyOS kernel ships with the BORE scheduler and is compiled${NC}"
    echo -e "${DG}  with full CachyOS optimisations. Pairs with scx_lavd for best results.${NC}"
    echo ""
    if confirm "Install CachyOS kernel (linux-cachyos + linux-cachyos-headers)?"; then
        if ! sudo pacman -S --needed linux-cachyos linux-cachyos-headers --noconfirm; then
            print_err "CachyOS kernel install failed — skipping"
        else
            print_ok "CachyOS kernel installed  ${DG}//  set it as default in your bootloader${NC}"
            print_info "GRUB: sudo grub-mkconfig -o /boot/grub/grub.cfg"
            print_info "systemd-boot: it should appear automatically on next boot"
        fi
    else
        print_skip "CachyOS kernel"
    fi

    # ── SCX SCHEDULERS ──
    echo ""
    echo -e "${DG}  scx-scheds provides userspace schedulers including scx_lavd —${NC}"
    echo -e "${DG}  the latency-aware scheduler that makes CachyOS feel so responsive.${NC}"
    echo ""
    if confirm "Install scx-scheds (userspace schedulers — scx_lavd, scx_bpfland, etc.)?"; then
        if sudo pacman -S --needed scx-scheds --noconfirm; then
            print_ok "scx schedulers installed${NC}"
            if confirm "Enable scx_lavd at boot?"; then
                sudo tee /etc/scx.conf > /dev/null <<'EOF'
SCX_SCHEDULER=scx_lavd
SCX_FLAGS=--autopilot
EOF
                sudo systemctl enable scx
                sudo systemctl start scx
                print_ok "scx_lavd enabled at boot  ${DG}//  autopilot mode${NC}"
            fi
        else
            print_err "scx-scheds install failed — skipping"
        fi
    else
        print_skip "scx schedulers"
    fi

    # ── CACHYOS GAMING META ──
    echo ""
    echo -e "${DG}  cachyos-gaming-meta pulls in: gamemode, mangohud, proton-cachyos,${NC}"
    echo -e "${DG}  wine-cachyos, performance tweaks, and supporting tools.${NC}"
    echo -e "${DG}  If you game on this machine, just say yes.${NC}"
    echo ""
    if confirm "Install CachyOS gaming meta?"; then
        if sudo pacman -S --needed cachyos-gaming-meta --noconfirm; then
            print_ok "Gaming meta installed  ${DG}//  the hunt begins${NC}"
        else
            print_err "Gaming meta install failed — skipping"
        fi
    else
        print_skip "CachyOS gaming meta"
    fi

    echo ""
    print_ok "CachyOS integration complete  ${DG}//  the dynasty runs on optimised silicon${NC}"
    print_info "Previous pacman.conf backed up to /etc/pacman.conf.necrodermis-backup"
}
